import express from "express";
import stripe from "../lib/stripe.js";

const router = express.Router();

const resolveStripeClient = (req) => {
  const mode = req.body?.mode || req.query?.mode || req.headers["x-stripe-mode"];
  if (typeof stripe.getStripeClient === "function") {
    return stripe.getStripeClient(mode);
  }
  return stripe;
};

const resolvePublishableKey = (req) => {
  const mode = req.body?.mode || req.query?.mode || req.headers["x-stripe-mode"];
  if (typeof stripe.getPublishableKey === "function") {
    return stripe.getPublishableKey(mode);
  }
  return process.env.STRIPE_PUBLISHABLE_KEY;
};

router.post("/payment-sheet", async (req, res) => {
  try {
    const stripeClient = resolveStripeClient(req);
    const publishableKey = resolvePublishableKey(req);
    if (!stripeClient || !publishableKey) {
      return res.status(500).json({ error: "Stripe keys are not configured" });
    }

    const { amount, currency = "usd" } = req.body;
    const parsedAmount = Number(amount);

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const customer = await stripeClient.customers.create();
    const customerSession = await stripeClient.customerSessions.create({
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
    const ephemeralKey = await stripeClient.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: "2023-10-16" }
    );
    const paymentIntent = await stripeClient.paymentIntents.create({
      amount: Math.round(parsedAmount * 100),
      currency,
      customer: customer.id,
      automatic_payment_methods: { enabled: true }
    });

    return res.json({
      paymentIntent: paymentIntent.client_secret,
      customer: customer.id,
      ephemeralKey: ephemeralKey.secret,
      customerSessionClientSecret: customerSession.client_secret,
      publishableKey
    });
  } catch (error) {
    console.error("Stripe payment-sheet error:", error);
    return res.status(500).json({ error: error.message });
  }
});

export default router;

