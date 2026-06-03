import * as admin from "firebase-admin";

// ═══════════════════════════════════════════════════════════════════════════
// INISIALISASI FIREBASE ADMIN
// ═══════════════════════════════════════════════════════════════════════════

admin.initializeApp();

// ═══════════════════════════════════════════════════════════════════════════
// EXPORT SEMUA CLOUD FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

// ── Booking Triggers ──
// Menangani perubahan status booking, reschedule request, dan respon reschedule
export { onBookingUpdated } from "./triggers/booking-triggers";

// ── Payout Triggers ──
// Notifikasi request pencairan baru (ke Admin) dan update status (ke Mitra)
export { onPayoutCreated, onPayoutUpdated } from "./triggers/payout-triggers";

// ── Review Trigger ──
// Notifikasi ulasan baru dari Customer ke Mitra
export { onReviewCreated } from "./triggers/review-triggers";

// ── Mitra Triggers ──
// Notifikasi pendaftaran Mitra baru (ke Admin) dan perubahan status verifikasi (ke Mitra)
export { onMitraCreated, onMitraUpdated } from "./triggers/mitra-triggers";

// ── Scheduled Functions ──
// Pengingat bermain H-1 dan 2 jam sebelum jadwal (setiap 15 menit)
export { sendBookingReminders } from "./scheduled/booking-reminders";
