import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { sendNotification, getUserFcmToken, getDb } from "../utils/fcm-sender";

// ═══════════════════════════════════════════════════════════════════════════
// SCHEDULED: PENGINGAT BERMAIN (H-1 & 2 JAM)
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Cron job yang berjalan setiap 15 menit.
 *
 * Logika:
 * 1. Query semua booking dengan status 'dikonfirmasi'
 * 2. Untuk setiap booking, hitung jarak waktu ke jadwal bermain
 * 3. Jika < 24 jam dan belum notifikasi H-1 → kirim reminder H-1
 * 4. Jika < 2 jam dan belum notifikasi 2 jam → kirim reminder 2 jam
 */
export const sendBookingReminders = onSchedule(
  {
    schedule: "every 15 minutes",
    timeZone: "Asia/Jakarta",
    region: "asia-southeast2",
  },
  async () => {
    const db = getDb();
    const now = new Date();

    console.log(`⏰ [Reminder] Running at ${now.toISOString()}`);

    // Query booking yang dikonfirmasi (masih aktif, belum selesai)
    const bookingsSnap = await db
      .collection("bookings")
      .where("status", "==", "dikonfirmasi")
      .get();

    if (bookingsSnap.empty) {
      console.log("⏰ [Reminder] No confirmed bookings found.");
      return;
    }

    let h1Count = 0;
    let h2Count = 0;

    for (const doc of bookingsSnap.docs) {
      const data = doc.data();

      // Parse tanggal bermain
      const tanggal = data.tanggal;
      if (!tanggal) continue;

      let playDate: Date;
      if (tanggal instanceof admin.firestore.Timestamp) {
        playDate = tanggal.toDate();
      } else {
        continue;
      }

      // Parse jam mulai dari slot pertama (misal "19:00 - 20:00" → 19:00)
      const timeSlots = data.timeSlots as string[] | undefined;
      if (!timeSlots || timeSlots.length === 0) continue;

      const firstSlot = timeSlots[0]; // "19:00 - 20:00"
      const startTimeStr = firstSlot.split(" - ")[0]; // "19:00"
      const timeParts = startTimeStr.split(":");
      if (timeParts.length < 2) continue;

      const startHour = parseInt(timeParts[0], 10);
      const startMinute = parseInt(timeParts[1], 10);

      if (isNaN(startHour) || isNaN(startMinute)) continue;

      // Gabungkan tanggal + jam mulai → DateTime jadwal bermain
      const playDateTime = new Date(
        playDate.getFullYear(),
        playDate.getMonth(),
        playDate.getDate(),
        startHour,
        startMinute,
        0
      );

      // Hitung selisih waktu (dalam milidetik)
      const diffMs = playDateTime.getTime() - now.getTime();
      const diffHours = diffMs / (1000 * 60 * 60);

      // Skip jika jadwal sudah lewat
      if (diffHours < 0) continue;

      const userId = data.userId;
      if (!userId) continue;

      const bookingId = doc.id;
      const bookingDisplayId = data.bookingId || bookingId.substring(0, 8);
      const fieldName = data.fieldName || "Lapangan";

      // ── Pengingat H-1 (kurang dari 24 jam) ──
      if (diffHours <= 24 && diffHours > 2 && !data.isH1Notified) {
        const userToken = await getUserFcmToken(userId);
        if (userToken) {
          await sendNotification({
            token: userToken,
            title: "Pengingat Bermain Besok 🏟️",
            body: `Jadwal bermain di ${fieldName} tinggal ${Math.round(diffHours)} jam lagi (${firstSlot}). Jangan lupa persiapan ya!`,
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

        // Tandai sudah dinotifikasi H-1
        await doc.ref.update({ isH1Notified: true });
        h1Count++;
      }

      // ── Pengingat 2 Jam ──
      if (diffHours <= 2 && diffHours > 0 && !data.is2HNotified) {
        const userToken = await getUserFcmToken(userId);
        if (userToken) {
          await sendNotification({
            token: userToken,
            title: "Segera Bermain! ⏰",
            body: `${Math.round(diffHours * 60)} menit lagi jadwal bermain di ${fieldName} (${firstSlot}). Ayo berangkat!`,
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

        // Tandai sudah dinotifikasi 2 jam
        await doc.ref.update({ is2HNotified: true });
        h2Count++;
      }
    }

    console.log(
      `⏰ [Reminder] Done. H-1: ${h1Count}, 2H: ${h2Count} / ${bookingsSnap.size} bookings scanned.`
    );
  }
);
