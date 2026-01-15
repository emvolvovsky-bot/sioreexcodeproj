import express from "express";
import stripe from "../lib/stripe.js";

const router = express.Router();

router.post("/payment-sheet", async (req, res) => {
  try {
    if (!process.env.STRIPE_SECRET_KEY || !process.env.STRIPE_PUBLISHABLE_KEY) {
      return res.status(500).json({ error: "Stripe keys are not configured" });
    }

    const { amount, currency = "usd" } = req.body;
    const parsedAmount = Number(amount);

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const customer = await stripe.customers.create();
    const customerSession = await stripe.customerSessions.create({
      customer: customer.id,
      components: {
        mobile_payment_element: {
          enabled: true,
          features: {
            payment_method_save: "enabled",
            payment_method_redisplay: "enabled",
            payment_method_remove: "enabled"
          }
        }
      }
    });
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(parsedAmount * 100),
      currency,
      customer: customer.id,
      automatic_payment_methods: { enabled: true }
    });

    return res.json({
      paymentIntent: paymentIntent.client_secret,
      customer: customer.id,
      customerSessionClientSecret: customerSession.client_secret,
      publishableKey: process.env.STRIPE_PUBLISHABLE_KEY
    });
  } catch (error) {
    console.error("Stripe payment-sheet error:", error);
    return res.status(500).json({ error: error.message });
  }
});

export default router;

