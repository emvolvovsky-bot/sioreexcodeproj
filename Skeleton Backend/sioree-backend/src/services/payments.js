import Stripe from "stripe";

// Initialize Stripe only when a key is provided so local dev without Stripe still works
const stripeKey = process.env.STRIPE_SECRET_KEY;
let stripe = null;

if (stripeKey && stripeKey.trim() !== "") {
  try {
    stripe = new Stripe(stripeKey);
    console.log("✅ Stripe initialized");
  } catch (err) {
    console.error("⚠️ Stripe initialization failed:", err.message);
  }
} else {
  console.log("⚠️ Stripe disabled — no STRIPE_SECRET_KEY found (ok for local dev).");
}

export async function createPaymentIntent(amount, hostStripeAccountId) {
  if (!stripe) throw new Error("Stripe is disabled (no API key provided).");

  const amountInCents = Math.round(amount * 100);
  const params = {
    amount: amountInCents,
    currency: "usd",
    automatic_payment_methods: { enabled: true }
  };

  if (hostStripeAccountId && hostStripeAccountId.trim() !== "") {
    params.transfer_data = {
      destination: hostStripeAccountId,
      amount: Math.floor(amountInCents * 0.9) // 10% platform fee
    };
  }

  return await stripe.paymentIntents.create(params);
}

export async function createPaymentMethod(cardDetails) {
  if (!stripe) throw new Error("Stripe is disabled.");

  const { number, exp_month, exp_year, cvc, zip } = cardDetails;
  return await stripe.paymentMethods.create({
    type: "card",
    card: { number, exp_month, exp_year, cvc },
    billing_details: { address: { postal_code: zip } }
  });
}

export async function confirmPaymentIntent(paymentIntentId, paymentMethodId) {
  if (!stripe) throw new Error("Stripe is disabled.");

  return await stripe.paymentIntents.confirm(paymentIntentId, {
    payment_method: paymentMethodId
  });
}

export default stripe;
