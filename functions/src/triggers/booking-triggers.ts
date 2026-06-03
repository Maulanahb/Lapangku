import * as admin from "firebase-admin";
import {
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { sendNotification, getUserFcmToken, getDb } from "../utils/fcm-sender";

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
    minInstances: 1,
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
        // ── Pembayaran berhasil (Midtrans webhook) → Kirim ke CUSTOMER & MITRA ──
        case "dikonfirmasi": {
          const userId = after.userId;
          const mitraId = after.mitraId;

          if (userId) {
            const userToken = await getUserFcmToken(userId);
            if (userToken) {
              await sendNotification({
                token: userToken,
                title: "Pembayaran Berhasil ✅",
                body: `Pesanan ${bookingDisplayId} untuk ${fieldName} telah dikonfirmasi. Selamat bermain!`,
                data: { type: "booking", targetId: bookingId, bookingId: bookingDisplayId },
                saveToFirestore: true,
                targetUserId: userId,
                notificationType: "booking",
              });
            }
          }

          if (mitraId) {
            const mitraToken = await getUserFcmToken(mitraId);
            if (mitraToken) {
              await sendNotification({
                token: mitraToken,
                title: "Pembayaran Masuk 💰",
                body: `${after.userName || "Penyewa"} telah membayar untuk ${fieldName}. Pesanan otomatis dikonfirmasi.`,
                data: { type: "booking", targetId: bookingId, bookingId: bookingDisplayId },
                saveToFirestore: true,
                targetUserId: mitraId,
                notificationType: "booking",
              });
            }
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

        // ── Pesanan dibatalkan → Kirim ke CUSTOMER & MITRA ──
        case "dibatalkan": {
          const userId = after.userId;
          const mitraId = after.mitraId;

          if (userId) {
            const userToken = await getUserFcmToken(userId);
            if (userToken) {
              await sendNotification({
                token: userToken,
                title: "Pesanan Dibatalkan",
                body: `Pesanan ${bookingDisplayId} untuk ${fieldName} telah dibatalkan.`,
                data: { type: "booking", targetId: bookingId, bookingId: bookingDisplayId },
                saveToFirestore: true,
                targetUserId: userId,
                notificationType: "booking",
              });
            }
          }

          if (mitraId) {
            const mitraToken = await getUserFcmToken(mitraId);
            if (mitraToken) {
              await sendNotification({
                token: mitraToken,
                title: "Pesanan Dibatalkan",
                body: `Pesanan ${bookingDisplayId} untuk ${fieldName} telah dibatalkan.`,
                data: { type: "booking", targetId: bookingId, bookingId: bookingDisplayId },
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
    // Update totalPendapatan stats when booking is completed
    if (after.status === 'selesai') {
      const db = getDb();
      const STATS_DOC = db.collection("metadata").doc("stats");
      await STATS_DOC.set({
        totalPendapatan: admin.firestore.FieldValue.increment(after.totalBayar ?? 0)
      }, { merge: true });
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
