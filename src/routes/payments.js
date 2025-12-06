import express from "express";
import { createPaymentIntent } from "../services/payments.js";
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

    const { number, exp_month, exp_year, cvc, name } = req.body;
    
    if (!number || !exp_month || !exp_year || !cvc) {
      return res.status(400).json({ error: "Card details are required" });
    }

    // In production, create payment method via Stripe API
    // For now, return a mock payment method
    const paymentMethod = {
      id: "pm_mock_" + Date.now(),
      type: "card",
      card: {
        last4: number.slice(-4),
        brand: "visa",
        exp_month: exp_month,
        exp_year: exp_year
      }
    };

    res.json({ paymentMethod });
  } catch (err) {
    console.error("Create payment method error:", err);
    res.status(500).json({ error: "Failed to create payment method" });
  }
});

export default router;
