import * as admin from "firebase-admin";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import * as crypto from "crypto";
import { getDb } from "../utils/fcm-sender";

const REGION = "asia-southeast2";
const MIDTRANS_SNAP_URL =
  "https://app.sandbox.midtrans.com/snap/v1/transactions";

// ── Callable: Create Midtrans Snap Transaction ────────────────────────────
export const createMidtransTransaction = onCall(
  { 
    region: REGION,
    secrets: ["MIDTRANS_SERVER_KEY"],
  },
  async (request) => {
    const { bookingId, totalBayar, customerName, customerEmail } =
      request.data;
    console.log("createMidtransTransaction: request received", { bookingId, totalBayar, customerName, customerEmail });

    if (!bookingId || !totalBayar) {
      throw new HttpsError(
        "invalid-argument",
        "bookingId and totalBayar are required"
      );
    }

    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    if (!serverKey)
      throw new HttpsError("internal", "Midtrans server key not configured");

    const authHeader =
      "Basic " + Buffer.from(serverKey + ":").toString("base64");

    const payload = {
      transaction_details: {
        order_id: bookingId,
        gross_amount: totalBayar,
      },
      customer_details: {
        first_name: customerName ?? "Customer",
        email: customerEmail ?? "",
      },
      expiry: { unit: "minutes", duration: 15 },
    };

    const response = await fetch(MIDTRANS_SNAP_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: authHeader,
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const err = await response.text();
      throw new HttpsError("internal", `Midtrans error: ${err}`);
    }

    const data = (await response.json()) as {
      token: string;
      redirect_url: string;
    };
    return { snap_token: data.token, payment_url: data.redirect_url };
  }
);

// ── HTTP: Midtrans Webhook ────────────────────────────────────────────────
export const midtransWebhook = onRequest(
  { 
    region: REGION,
    secrets: ["MIDTRANS_SERVER_KEY"],
  },
  async (req, res) => {
    console.log("midtransWebhook: HTTP POST request received, body:", JSON.stringify(req.body));
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const payload = req.body as {
      order_id: string;
      status_code: string;
      gross_amount: string;
      signature_key: string;
      transaction_status: string;
    };

    if (!payload || !payload.order_id) {
      res.status(200).send("OK");
      return;
    }

    const serverKey = process.env.MIDTRANS_SERVER_KEY;
    if (!serverKey) {
      res.status(500).send("Server key not configured");
      return;
    }

    // Verify Midtrans signature: SHA512(order_id + status_code + gross_amount + server_key)
    const expectedSignature = crypto
      .createHash("sha512")
      .update(
        payload.order_id +
          payload.status_code +
          payload.gross_amount +
          serverKey
      )
      .digest("hex");

    if (expectedSignature !== payload.signature_key) {
      res.status(403).send("Invalid signature");
      return;
    }

    const bookingId = payload.order_id;
    console.log("midtransWebhook: searching for booking ID in Firestore:", bookingId);
    const db = getDb();
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      console.warn("midtransWebhook: booking ID not found in Firestore:", bookingId);
      res.status(404).send("Booking not found");
      return;
    }
    console.log("midtransWebhook: current status in Firestore is", bookingSnap.data()?.status);

    const now = admin.firestore.Timestamp.now();
    const currentData = bookingSnap.data()!;
    const timeline = Array.isArray(currentData.statusTimeline)
      ? [...currentData.statusTimeline]
      : [];

    let newStatus: string | null = null;
    const { transaction_status } = payload;

    if (
      transaction_status === "settlement" ||
      transaction_status === "capture"
    ) {
      newStatus = "dikonfirmasi";
    } else if (
      transaction_status === "expire" ||
      transaction_status === "cancel" ||
      transaction_status === "deny"
    ) {
      newStatus = "dibatalkan";
    }

    if (!newStatus) {
      console.log("midtransWebhook: intermediary status received, no status change required:", transaction_status);
      res.status(200).send("OK");
      return;
    }

    console.log(`midtransWebhook: updating booking status to ${newStatus}`);
    timeline.push({ status: newStatus, waktu: now });

    await bookingRef.update({
      status: newStatus,
      statusTimeline: timeline,
      updatedAt: now,
      paymentTransactionId: payload.order_id,
    });
    console.log("midtransWebhook: booking successfully updated in Firestore");

    res.status(200).send("OK");
  }
);
