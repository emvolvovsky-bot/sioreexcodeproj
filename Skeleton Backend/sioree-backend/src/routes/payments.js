import express from "express";
import { createPaymentIntent, confirmPaymentIntent, createPaymentMethod } from "../services/payments.js";
import db from "../db/database.js";
import jwt from "jsonwebtoken";

const router = express.Router();

// Helper to get user ID from token
function getUserIdFromToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) return null;
  const token = authHeader.substring(7);
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key-change-in-production");
    return decoded.userId;
  } catch (err) {
    return null;
  }
}

// POST /api/payments/create-intent
router.post("/create-intent", async (req, res) => {
  try {
    const { amount, hostStripeAccountId } = req.body;
    
    if (!amount) {
      return res.status(400).json({ error: "Amount is required" });
    }
    
    // Normalize hostStripeAccountId - convert empty string, null, or undefined to null
    const normalizedHostStripeAccountId = 
      hostStripeAccountId && 
      hostStripeAccountId !== "" && 
      hostStripeAccountId !== "null" && 
      hostStripeAccountId !== "undefined"
        ? hostStripeAccountId 
        : null;
    
    console.log("📥 Creating payment intent:", { amount, hostStripeAccountId: normalizedHostStripeAccountId });
    
    const paymentIntent = await createPaymentIntent(amount, normalizedHostStripeAccountId);
    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    console.error("❌ Stripe error:", err);
    res.status(400).json({ error: err.message || "Failed to create payment intent" });
  }
});

// GET /api/payments/methods - Get saved payment methods
router.get("/methods", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    // For now, return empty array - in production, integrate with Stripe Customer API
    // This would fetch payment methods from Stripe Customer
    // Format: { paymentMethods: [...] }
    res.json({ paymentMethods: [] });
  } catch (err) {
    console.error("Get payment methods error:", err);
    res.status(500).json({ error: "Failed to fetch payment methods" });
  }
});

// POST /api/payments/save-method - Save payment method
router.post("/save-method", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { paymentMethodId, setAsDefault } = req.body;
    
    if (!paymentMethodId) {
      return res.status(400).json({ error: "Payment method ID is required" });
    }

    // In production, attach payment method to Stripe Customer
    // For now, return a mock response
    const savedMethod = {
      id: paymentMethodId,
      type: "card",
      last4: "4242",
      brand: "visa",
      expMonth: 12,
      expYear: 2025,
      isDefault: setAsDefault || false,
      createdAt: new Date().toISOString()
    };

    res.json(savedMethod);
  } catch (err) {
    console.error("Save payment method error:", err);
    res.status(500).json({ error: "Failed to save payment method" });
  }
});

// DELETE /api/payments/methods/:id - Delete payment method
router.delete("/methods/:id", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    // In production, detach payment method from Stripe Customer
    res.json({ success: true });
  } catch (err) {
    console.error("Delete payment method error:", err);
    res.status(500).json({ error: "Failed to delete payment method" });
  }
});

// POST /api/payments/set-default - Set default payment method
router.post("/set-default", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { paymentMethodId } = req.body;
    
    if (!paymentMethodId) {
      return res.status(400).json({ error: "Payment method ID is required" });
    }

    // In production, update Stripe Customer default payment method
    res.json({ success: true });
  } catch (err) {
    console.error("Set default payment method error:", err);
    res.status(500).json({ error: "Failed to set default payment method" });
  }
});

// POST /api/payments/create-method - Create payment method from card details
router.post("/create-method", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { number, exp_month, exp_year, cvc, zip } = req.body;
    
    if (!number || !exp_month || !exp_year || !cvc) {
      return res.status(400).json({ error: "Card details are required" });
    }

    // Create payment method via Stripe API
    const paymentMethod = await createPaymentMethod({
      number: number.replace(/\s/g, ""), // Remove spaces
      exp_month: parseInt(exp_month),
      exp_year: parseInt(exp_year),
      cvc: cvc,
      zip: zip
    });

    res.json({ paymentMethod });
  } catch (err) {
    console.error("Create payment method error:", err);
    res.status(500).json({ error: err.message || "Failed to create payment method" });
  }
});

// POST /api/payments/confirm - Confirm payment with payment method
router.post("/confirm", async (req, res) => {
  try {
    const userId = getUserIdFromToken(req);
    if (!userId) return res.status(401).json({ error: "Unauthorized" });

    const { paymentIntentId, paymentMethodId } = req.body;
    
    if (!paymentIntentId || !paymentMethodId) {
      return res.status(400).json({ error: "Payment intent ID and payment method ID are required" });
    }

    // Confirm payment intent with Stripe
    const paymentIntent = await confirmPaymentIntent(paymentIntentId, paymentMethodId);
    
    // Try to create payment record in database (if table exists)
    let paymentRecord = null;
    try {
      const result = await db.query(
        `INSERT INTO payments (user_id, amount, status, transaction_id, payment_method, created_at)
         VALUES ($1, $2, $3, $4, $5, NOW())
         RETURNING *`,
        [
          userId,
          paymentIntent.amount / 100, // Convert from cents to dollars
          paymentIntent.status === "succeeded" ? "paid" : "pending",
          paymentIntent.id,
          paymentMethodId
        ]
      );
      paymentRecord = result.rows[0];
    } catch (dbErr) {
      // If payments table doesn't exist, continue without saving to DB
      console.warn("Payments table doesn't exist, skipping DB save:", dbErr.message);
    }

    // Return payment object matching iOS Payment model
    const payment = {
      id: paymentRecord?.id?.toString() || paymentIntent.id,
      userId: userId,
      amount: paymentIntent.amount / 100, // Convert from cents to dollars
      method: "credit_card", // or determine from payment method type
      status: paymentIntent.status === "succeeded" ? "paid" : "pending",
      transactionId: paymentIntent.id,
      description: paymentIntent.description || "Sioree Payment",
      createdAt: paymentRecord?.created_at?.toISOString() || new Date().toISOString()
    };

    res.json(payment);
  } catch (err) {
    console.error("Confirm payment error:", err);
    res.status(500).json({ error: err.message || "Failed to confirm payment" });
  }
});

export default router;
