import express from "express";
import stripe from "../lib/stripe.js";
import { db } from "../db/database.js";

const router = express.Router();

const respondStripeError = (res, status, message, details = {}) => {
  const error = {
    message,
    type: details.type,
    code: details.code,
    param: details.param
  };
  return res.status(status).json({ error });
};

const toStripeErrorDetails = (error) => {
  if (!error || typeof error !== "object") {
    return { message: "Stripe error", type: "api_error" };
  }
  return {
    message: error.message || "Stripe error",
    type: error.type || "api_error",
    code: error.code,
    param: error.param
  };
};

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
    console.log("💳 Stripe payment-sheet:", req.body);
    const stripeClient = resolveStripeClient(req);
    const publishableKey = resolvePublishableKey(req);
    if (!stripeClient || !publishableKey) {
      return respondStripeError(res, 500, "Stripe keys are not configured", {
        type: "configuration_error"
      });
    }

    const { amount, currency = "usd", eventId } = req.body;
    const parsedAmount = Number(amount);

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return respondStripeError(res, 400, "Invalid amount", {
        type: "invalid_request_error",
        param: "amount"
      });
    }

    let eventRow = null;
    let totalAmount = parsedAmount;
    let hostStripeAccountId = null;
    let ticketPrice = null;

    if (eventId && typeof eventId === "string") {
      const eventResult = await db.query(
        "SELECT creator_id, ticket_price FROM events WHERE id = $1",
        [eventId]
      );
      if (eventResult.rows.length === 0) {
        return respondStripeError(res, 404, "Event not found", {
          type: "invalid_request_error",
          param: "eventId"
        });
      }

      eventRow = eventResult.rows[0];
      ticketPrice = Number(eventRow.ticket_price);
      if (!Number.isFinite(ticketPrice) || ticketPrice <= 0) {
        return respondStripeError(res, 400, "Event ticket price is invalid", {
          type: "invalid_request_error",
          param: "ticketPrice"
        });
      }

      const hostResult = await db.query(
        "SELECT stripe_account_id FROM users WHERE id = $1",
        [eventRow.creator_id]
      );
      hostStripeAccountId = hostResult.rows[0]?.stripe_account_id;
      if (!hostStripeAccountId) {
        console.warn(
          "Stripe payment-sheet: host has no connected account, skipping transfer.",
          { eventId, hostId: eventRow.creator_id }
        );
      }

      totalAmount = ticketPrice * 1.05;
      if (Math.abs(parsedAmount - totalAmount) > 0.01) {
        console.warn(
          "Stripe payment-sheet amount mismatch:",
          { parsedAmount, totalAmount, ticketPrice, eventId }
        );
      }
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
    const totalAmountInCents = Math.round(totalAmount * 100);
    const paymentIntentParams = {
      amount: totalAmountInCents,
      currency,
      customer: customer.id,
      automatic_payment_methods: { enabled: true }
    };

    if (hostStripeAccountId && ticketPrice && eventRow) {
      const stripeFee = ticketPrice * 0.029 + 0.3;
      const hostPayout = Math.max(0, ticketPrice - stripeFee);
      const unclampedHostPayoutCents = Math.round(hostPayout * 100);
      const hostPayoutCents = Math.min(totalAmountInCents, unclampedHostPayoutCents);
      const applicationFeeAmount = Math.max(0, totalAmountInCents - hostPayoutCents);

      paymentIntentParams.application_fee_amount = applicationFeeAmount;
      paymentIntentParams.transfer_data = {
        destination: hostStripeAccountId,
        amount: hostPayoutCents
      };
      paymentIntentParams.metadata = {
        eventId,
        hostId: eventRow.creator_id?.toString() || ""
      };
    }

    const paymentIntent = await stripeClient.paymentIntents.create(paymentIntentParams);

    return res.json({
      paymentIntent: paymentIntent.client_secret,
      customer: customer.id,
      ephemeralKey: ephemeralKey.secret,
      customerSessionClientSecret: customerSession.client_secret,
      publishableKey
    });
  } catch (error) {
    console.error("Stripe payment-sheet error:", error);
    const details = toStripeErrorDetails(error);
    return respondStripeError(res, 500, details.message, details);
  }
});

export default router;

