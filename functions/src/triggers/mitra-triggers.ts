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
// MITRA TRIGGERS
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Trigger: Saat dokumen mitra baru dibuat di koleksi `mitra`.
 * → Kirim notifikasi ke semua Admin bahwa ada pendaftaran Mitra baru.
 */
export const onMitraCreated = onDocumentCreated(
  {
    document: "mitra/{mitraId}",
    database: "lapangku-db",
    region: "asia-southeast2",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const mitraName =
      data.businessName ||
      data.namaBisnis ||
      data.MitraName ||
      "Mitra Baru";

    // Kirim ke semua Admin
    const adminTokens = await getAdminFcmTokens();

    for (const admin of adminTokens) {
      await sendNotification({
        token: admin.token,
        title: "Pendaftaran Mitra Baru 🏢",
        body: `${mitraName} telah mendaftar sebagai Mitra. Periksa dan verifikasi dokumen mereka.`,
        data: {
          type: "system",
          targetId: event.params.mitraId,
        },
        saveToFirestore: true,
        targetUserId: admin.uid,
        notificationType: "system",
      });
    }
  }
);

/**
 * Trigger: Saat dokumen Mitra diperbarui di koleksi `mitra`.
 * → Kirim notifikasi ke Mitra jika statusVerifikasi berubah.
 * → Kirim notifikasi ke Admin jika dokumen baru diupload.
 */
export const onMitraUpdated = onDocumentUpdated(
  {
    document: "mitra/{mitraId}",
    database: "lapangku-db",
    region: "asia-southeast2",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    const mitraId = event.params.mitraId;

    // ─── Status Verifikasi Berubah → Kirim ke MITRA ───
    const oldStatus = before.statusVerifikasi || before.isVerified;
    const newStatus = after.statusVerifikasi || after.isVerified;

    if (oldStatus !== newStatus) {
      const mitraToken = await getUserFcmToken(mitraId);
      if (!mitraToken) return;

      // Cek status baru
      const isVerified =
        newStatus === "aktif" || newStatus === true || newStatus === "verified";
      const isRejected =
        newStatus === "ditolak" || newStatus === "rejected";

      if (isVerified) {
        await sendNotification({
          token: mitraToken,
          title: "Akun Terverifikasi ✅",
          body: "Selamat! Akun Mitra Anda telah diverifikasi. Anda sekarang dapat menerima pesanan.",
          data: {
            type: "system",
            targetId: mitraId,
          },
          saveToFirestore: true,
          targetUserId: mitraId,
          notificationType: "system",
        });
      } else if (isRejected) {
        await sendNotification({
          token: mitraToken,
          title: "Verifikasi Ditolak ❌",
          body: "Maaf, verifikasi akun Mitra Anda ditolak. Periksa kembali dokumen yang diunggah.",
          data: {
            type: "system",
            targetId: mitraId,
          },
          saveToFirestore: true,
          targetUserId: mitraId,
          notificationType: "system",
        });
      }
    }

    // ─── Dokumen Baru Diupload → Kirim ke ADMIN ───
    const docsChanged =
      (before.ktpUrl !== after.ktpUrl && after.ktpUrl) ||
      (before.dokumenKTP !== after.dokumenKTP && after.dokumenKTP) ||
      (before.npwpUrl !== after.npwpUrl && after.npwpUrl) ||
      (before.dokumenNPWP !== after.dokumenNPWP && after.dokumenNPWP);

    if (docsChanged) {
      const mitraName =
        after.businessName ||
        after.namaBisnis ||
        after.MitraName ||
        "Mitra";

      const adminTokens = await getAdminFcmTokens();

      for (const admin of adminTokens) {
        await sendNotification({
          token: admin.token,
          title: "Dokumen Mitra Diperbarui 📄",
          body: `${mitraName} telah mengunggah dokumen baru. Silakan tinjau untuk verifikasi.`,
          data: {
            type: "system",
            targetId: mitraId,
          },
          saveToFirestore: true,
          targetUserId: admin.uid,
          notificationType: "system",
        });
      }
    }
  }
);
