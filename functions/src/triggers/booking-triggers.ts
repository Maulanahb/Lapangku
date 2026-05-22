import {
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { sendNotification, getUserFcmToken } from "../utils/fcm-sender";

// ═══════════════════════════════════════════════════════════════════════════
// BOOKING TRIGGERS
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Trigger: Saat dokumen di koleksi `bookings` berubah.
 *
 * Menangani:
 * 1. Perubahan status booking → kirim notifikasi ke Customer atau Mitra
 * 2. Pengajuan reschedule → kirim ke Mitra
 * 3. Respon reschedule (approved/rejected) → kirim ke Customer
 */
export const onBookingUpdated = onDocumentUpdated(
  {
    document: "bookings/{bookingId}",
    database: "lapangku-db",
    region: "asia-southeast2",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    const bookingId = event.params.bookingId;
    const bookingDisplayId = after.bookingId || bookingId.substring(0, 8);
    const fieldName = after.fieldName || "Lapangan";

    // ─────────────────────────────────────────────────────────────────────
    // 1. PERUBAHAN STATUS BOOKING
    // ─────────────────────────────────────────────────────────────────────
    if (before.status !== after.status) {
      const newStatus = after.status as string;

      switch (newStatus) {
        // ── Customer upload bukti bayar → Kirim ke MITRA ──
        case "menunggu_konfirmasi": {
          const mitraId = after.mitraId;
          if (!mitraId) break;

          const mitraToken = await getUserFcmToken(mitraId);
          if (mitraToken) {
            await sendNotification({
              token: mitraToken,
              title: "Pesanan Baru! 🎾",
              body: `${after.userName || "Penyewa"} telah membayar untuk ${fieldName}. Segera konfirmasi pesanan.`,
              data: {
                type: "booking",
                targetId: bookingId,
                bookingId: bookingDisplayId,
              },
              saveToFirestore: true,
              targetUserId: mitraId,
              notificationType: "booking",
            });
          }
          break;
        }

        // ── Mitra konfirmasi → Kirim ke CUSTOMER ──
        case "dikonfirmasi": {
          const userId = after.userId;
          if (!userId) break;

          const userToken = await getUserFcmToken(userId);
          if (userToken) {
            await sendNotification({
              token: userToken,
              title: "Booking Dikonfirmasi ✅",
              body: `Pesanan ${bookingDisplayId} untuk ${fieldName} telah dikonfirmasi. Selamat bermain!`,
              data: {
                type: "booking",
                targetId: bookingId,
                bookingId: bookingDisplayId,
              },
              saveToFirestore: true,
              targetUserId: userId,
              notificationType: "booking",
            });
          }
          break;
        }

        // ── Mitra tolak → Kirim ke CUSTOMER ──
        case "ditolak": {
          const userId = after.userId;
          if (!userId) break;

          const alasan = after.alasanPenolakan || "Tidak ada alasan";
          const userToken = await getUserFcmToken(userId);
          if (userToken) {
            await sendNotification({
              token: userToken,
              title: "Booking Ditolak ❌",
              body: `Pesanan ${bookingDisplayId} ditolak oleh mitra. Alasan: ${alasan}`,
              data: {
                type: "booking",
                targetId: bookingId,
                bookingId: bookingDisplayId,
              },
              saveToFirestore: true,
              targetUserId: userId,
              notificationType: "booking",
            });
          }
          break;
        }

        // ── Customer batalkan → Kirim ke MITRA ──
        case "dibatalkan": {
          const mitraId = after.mitraId;
          if (!mitraId) break;

          // Hanya kirim ke mitra jika status sebelumnya sudah menunggu_konfirmasi
          // (berarti customer sudah bayar tapi membatalkan)
          if (before.status === "menunggu_konfirmasi") {
            const mitraToken = await getUserFcmToken(mitraId);
            if (mitraToken) {
              await sendNotification({
                token: mitraToken,
                title: "Pembatalan Pesanan",
                body: `${after.userName || "Penyewa"} membatalkan pesanan ${bookingDisplayId} untuk ${fieldName}.`,
                data: {
                  type: "booking",
                  targetId: bookingId,
                  bookingId: bookingDisplayId,
                },
                saveToFirestore: true,
                targetUserId: mitraId,
                notificationType: "booking",
              });
            }
          }
          break;
        }

        // ── Sistem auto-expire → Kirim ke CUSTOMER ──
        case "expired": {
          const userId = after.userId;
          if (!userId) break;

          const userToken = await getUserFcmToken(userId);
          if (userToken) {
            await sendNotification({
              token: userToken,
              title: "Booking Kedaluwarsa ⏰",
              body: `Pesanan ${bookingDisplayId} telah kedaluwarsa karena batas waktu pembayaran terlewat.`,
              data: {
                type: "booking",
                targetId: bookingId,
                bookingId: bookingDisplayId,
              },
              saveToFirestore: true,
              targetUserId: userId,
              notificationType: "payment",
            });
          }
          break;
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────
    // 2. PENGAJUAN RESCHEDULE (Customer → Mitra)
    // ─────────────────────────────────────────────────────────────────────
    if (
      !before.isRescheduleRequested &&
      after.isRescheduleRequested === true &&
      after.rescheduleStatus === "pending"
    ) {
      const mitraId = after.mitraId;
      if (mitraId) {
        const mitraToken = await getUserFcmToken(mitraId);
        if (mitraToken) {
          await sendNotification({
            token: mitraToken,
            title: "Pengajuan Reschedule 📅",
            body: `${after.userName || "Penyewa"} mengajukan perubahan jadwal untuk pesanan ${bookingDisplayId}.`,
            data: {
              type: "booking",
              targetId: bookingId,
              bookingId: bookingDisplayId,
            },
            saveToFirestore: true,
            targetUserId: mitraId,
            notificationType: "booking",
          });
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────
    // 3. RESPON RESCHEDULE (Mitra → Customer)
    // ─────────────────────────────────────────────────────────────────────
    if (before.rescheduleStatus !== after.rescheduleStatus) {
      const userId = after.userId;
      if (!userId) return;

      const userToken = await getUserFcmToken(userId);
      if (!userToken) return;

      if (after.rescheduleStatus === "approved") {
        await sendNotification({
          token: userToken,
          title: "Reschedule Disetujui ✅",
          body: `Pengajuan perubahan jadwal untuk pesanan ${bookingDisplayId} telah disetujui oleh mitra!`,
          data: {
            type: "booking",
            targetId: bookingId,
            bookingId: bookingDisplayId,
          },
          saveToFirestore: true,
          targetUserId: userId,
          notificationType: "booking",
        });
      } else if (after.rescheduleStatus === "rejected") {
        await sendNotification({
          token: userToken,
          title: "Reschedule Ditolak ❌",
          body: `Maaf, pengajuan perubahan jadwal untuk pesanan ${bookingDisplayId} ditolak oleh mitra.`,
          data: {
            type: "booking",
            targetId: bookingId,
            bookingId: bookingDisplayId,
          },
          saveToFirestore: true,
          targetUserId: userId,
          notificationType: "booking",
        });
      }
    }
  }
);
