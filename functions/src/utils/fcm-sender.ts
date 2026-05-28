import * as admin from "firebase-admin";
import { getFirestore } from "firebase-admin/firestore";
import { getApp } from "firebase-admin/app";

// ═══════════════════════════════════════════════════════════════════════════
// KONFIGURASI DATABASE
// ═══════════════════════════════════════════════════════════════════════════

// Named database yang digunakan oleh LapangKu
const DATABASE_ID = "lapangku-db";

/**
 * Mendapatkan instance Firestore yang mengarah ke named database 'lapangku-db'.
 * Semua Cloud Functions HARUS menggunakan ini untuk membaca koleksi utama
 * (bookings, lapangan, mitra, payouts, dll).
 */
export function getDb(): admin.firestore.Firestore {
  return getFirestore(getApp(), DATABASE_ID);
}

/**
 * Mendapatkan instance Firestore default (untuk fallback jika dibutuhkan).
 * Catatan: Semua koleksi utama sekarang berada di lapangku-db.
 */
export function getDefaultDb(): admin.firestore.Firestore {
  return getFirestore();
}

// ═══════════════════════════════════════════════════════════════════════════
// TIPE DATA
// ═══════════════════════════════════════════════════════════════════════════

interface SendNotificationOptions {
  /** FCM device token tujuan */
  token: string;
  /** Judul notifikasi */
  title: string;
  /** Isi pesan notifikasi */
  body: string;
  /** Data payload untuk navigasi (opsional) */
  data?: Record<string, string>;
  /** Jika true, simpan juga ke koleksi 'notifikasi' di Firestore */
  saveToFirestore?: boolean;
  /** User ID target — wajib jika saveToFirestore = true */
  targetUserId?: string;
  /** Tipe notifikasi: booking, payment, payout, review, system */
  notificationType?: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// KIRIM NOTIFIKASI
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Mengirim push notification via FCM dan opsional menyimpan ke Firestore.
 *
 * @param options - Konfigurasi notifikasi
 * @returns true jika berhasil, false jika gagal
 */
export async function sendNotification(
  options: SendNotificationOptions
): Promise<boolean> {
  const {
    token,
    title,
    body,
    data = {},
    saveToFirestore = true,
    targetUserId,
    notificationType = "system",
  } = options;

  // ─── Kirim FCM Push Notification ───
  try {
    await admin.messaging().send({
      token,
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        type: notificationType,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "lapangku_channel",
          priority: "high",
          defaultSound: true,
        },
      },
    });

    console.log(`✅ FCM sent to ${token.substring(0, 20)}... | ${title}`);
  } catch (error: any) {
    // Token tidak valid / perangkat sudah uninstall app
    if (
      error.code === "messaging/registration-token-not-registered" ||
      error.code === "messaging/invalid-registration-token"
    ) {
      console.warn(`⚠️ Invalid FCM token, removing from Firestore...`);
      await _removeInvalidToken(token);
    } else {
      console.error(`❌ FCM send error:`, error);
    }
    return false;
  }

  // ─── Simpan ke Firestore (koleksi notifikasi) ───
  if (saveToFirestore && targetUserId) {
    try {
      const db = getDb();
      await db.collection("notifikasi").add({
        customer_id: targetUserId,
        title,
        message: body,
        type: notificationType,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: data,
      });
    } catch (error) {
      console.error(`❌ Failed to save notification to Firestore:`, error);
    }
  }

  return true;
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: Get FCM Token
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Mendapatkan FCM token user dari koleksi 'users' (database lapangku-db).
 *
 * @param userId - UID user target
 * @returns FCM token string, atau null jika tidak ditemukan
 */
export async function getUserFcmToken(
  userId: string
): Promise<string | null> {
  try {
    const db = getDb();
    const userDoc = await db.collection("users").doc(userId).get();

    if (!userDoc.exists) return null;
    return userDoc.data()?.fcmToken || null;
  } catch (error) {
    console.error(`❌ Failed to get FCM token for ${userId}:`, error);
    return null;
  }
}

/**
 * Mendapatkan FCM token untuk semua Admin.
 *
 * @returns Array of { uid, token } untuk setiap admin yang memiliki token
 */
export async function getAdminFcmTokens(): Promise<
  Array<{ uid: string; token: string }>
> {
  try {
    const db = getDb();
    const adminsSnap = await db
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const tokens: Array<{ uid: string; token: string }> = [];

    for (const doc of adminsSnap.docs) {
      const token = doc.data().fcmToken;
      if (token) {
        tokens.push({ uid: doc.id, token });
      }
    }

    return tokens;
  } catch (error) {
    console.error(`❌ Failed to get admin FCM tokens:`, error);
    return [];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INTERNAL: Hapus token tidak valid
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Menghapus FCM token yang sudah tidak valid dari Firestore.
 */
async function _removeInvalidToken(invalidToken: string): Promise<void> {
  try {
    const db = getDb();
    const usersSnap = await db
      .collection("users")
      .where("fcmToken", "==", invalidToken)
      .get();

    const batch = db.batch();
    for (const doc of usersSnap.docs) {
      batch.update(doc.ref, {
        fcmToken: admin.firestore.FieldValue.delete(),
        fcmTokenUpdatedAt: admin.firestore.FieldValue.delete(),
      });
    }
    await batch.commit();
  } catch (error) {
    console.error(`❌ Failed to remove invalid token:`, error);
  }
}
