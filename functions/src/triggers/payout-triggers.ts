import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {
  sendNotification,
  getUserFcmToken,
  getAdminFcmTokens,
} from "../utils/fcm-sender";

// ═══════════════════════════════════════════════════════════════════════════
// PAYOUT TRIGGERS
// ═══════════════════════════════════════════════════════════════════════════

// Notif Admin: Ada request pencairan dana baru
export const onPayoutCreated = onDocumentCreated(
  {
    document: "payouts/{payoutId}",
    database: "lapangku-db",
    region: "asia-southeast2",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const mitraId = data.mitraId;
    const amount = data.amount || 0;
    const bankName = data.bankName || "";

    // Format jumlah ke Rupiah
    const formattedAmount = new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      minimumFractionDigits: 0,
    }).format(amount);

    // Kirim ke semua Admin
    const adminTokens = await getAdminFcmTokens();

    for (const admin of adminTokens) {
      await sendNotification({
        token: admin.token,
        title: "Permintaan Pencairan Dana Baru 💰",
        body: `Mitra ${mitraId} mengajukan pencairan ${formattedAmount} ke ${bankName}.`,
        data: {
          type: "payout",
          targetId: event.params.payoutId,
          mitraId: mitraId || "",
        },
        saveToFirestore: true,
        targetUserId: admin.uid,
        notificationType: "payout",
      });
    }
  }
);

// Notif Mitra: Status pencairan dana berubah (proses/sukses/gagal)
export const onPayoutUpdated = onDocumentUpdated(
  {
    document: "payouts/{payoutId}",
    database: "lapangku-db",
    region: "asia-southeast2",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Hanya proses jika status berubah
    if (before.status === after.status) return;

    const mitraId = after.mitraId;
    if (!mitraId) return;

    const amount = after.amount || 0;
    const formattedAmount = new Intl.NumberFormat("id-ID", {
      style: "currency",
      currency: "IDR",
      minimumFractionDigits: 0,
    }).format(amount);

    const newStatus = after.status as string;
    let title = "";
    let body = "";

    switch (newStatus) {
      case "processing":
        title = "Pencairan Dana Diproses 🔄";
        body = `Permintaan pencairan ${formattedAmount} sedang diproses oleh Admin.`;
        break;
      case "completed":
        title = "Pencairan Dana Berhasil ✅";
        body = `Pencairan ${formattedAmount} telah berhasil ditransfer ke rekening Anda.`;
        break;
      case "rejected":
        title = "Pencairan Dana Ditolak ❌";
        body = `Permintaan pencairan ${formattedAmount} ditolak.${after.notes ? ` Catatan: ${after.notes}` : ""}`;
        break;
      default:
        return; // Status lain tidak perlu notifikasi
    }

    const mitraToken = await getUserFcmToken(mitraId);
    if (mitraToken) {
      await sendNotification({
        token: mitraToken,
        title,
        body,
        data: {
          type: "payout",
          targetId: event.params.payoutId,
          status: newStatus,
        },
        saveToFirestore: true,
        targetUserId: mitraId,
        notificationType: "payout",
      });
    }
  }
);
