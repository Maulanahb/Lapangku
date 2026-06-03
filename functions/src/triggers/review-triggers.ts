import {
  onDocumentCreated,
} from "firebase-functions/v2/firestore";
import { sendNotification, getUserFcmToken } from "../utils/fcm-sender";
import { getDb } from "../utils/fcm-sender";

// ═══════════════════════════════════════════════════════════════════════════
// REVIEW TRIGGER
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Trigger: Saat ulasan baru ditambahkan di subkoleksi `lapangan/{fieldId}/reviews`.
 * → Kirim notifikasi ke Mitra pemilik lapangan.
 */
export const onReviewCreated = onDocumentCreated(
  {
    document: "lapangan/{fieldId}/reviews/{reviewId}",
    database: "lapangku-db",
    region: "asia-southeast2",
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const fieldId = event.params.fieldId;
    const userName = data.userName || "Penyewa";
    const rating = data.rating || 5;
    const comment = data.comment || "";

    // Ambil mitraId dari data review, atau fallback ke parent document
    let mitraId = data.mitraId;

    if (!mitraId) {
      try {
        const db = getDb();
        const fieldDoc = await db.collection("lapangan").doc(fieldId).get();
        mitraId =
          fieldDoc.data()?.mitraId ||
          fieldDoc.data()?.MitraId ||
          fieldDoc.data()?.id_pemilik;
      } catch (error) {
        console.error(`❌ Failed to get mitraId from field ${fieldId}:`, error);
        return;
      }
    }

    if (!mitraId) {
      console.warn(`⚠️ No mitraId found for field ${fieldId}`);
      return;
    }

    // Buat bintang visual untuk notifikasi
    const stars = "⭐".repeat(Math.min(rating, 5));
    const fieldName = data.fieldName || "lapangan Anda";

    const mitraToken = await getUserFcmToken(mitraId);
    if (mitraToken) {
      await sendNotification({
        token: mitraToken,
        title: `Ulasan Baru ${stars}`,
        body: `${userName} memberikan rating ${rating}/5 untuk ${fieldName}.${comment ? ` "${comment.substring(0, 50)}${comment.length > 50 ? "..." : ""}"` : ""}`,
        data: {
          type: "review",
          targetId: event.params.reviewId,
          fieldId,
        },
        saveToFirestore: true,
        targetUserId: mitraId,
        notificationType: "review",
      });
    }
  }
);
