import Stripe from "stripe";

const stripeApiKey = process.env.STRIPE_SECRET_KEY;
const stripe = stripeApiKey ? new Stripe(stripeApiKey) : null;
if (!stripeApiKey) {
  console.warn("⚠️ STRIPE_SECRET_KEY is missing. Payments are disabled.");
}

export async function createPaymentIntent(amount, hostStripeAccountId, metadata = {}) {
  try {
    if (!stripe) {
      throw new Error("Stripe is not configured");
    }
    // Convert amount to cents (Stripe uses smallest currency unit)
    const amountInCents = Math.round(amount * 100);
    
    const paymentIntentParams = {
      amount: amountInCents,
      currency: "usd",
      payment_method_types: ["card"],
      automatic_payment_methods: {
        enabled: true
      },
      metadata: {
        ...metadata
      }
    };
    
    // Only add transfer_data if hostStripeAccountId is provided and not empty (for bookings)
    // This should only be used for marketplace payments where we need to transfer to a connected account
    if (hostStripeAccountId && typeof hostStripeAccountId === 'string' && hostStripeAccountId.trim() !== '') {
      paymentIntentParams.transfer_data = {
        destination: hostStripeAccountId,
        amount: Math.floor(amountInCents * 0.98) // 2% platform fee
      };
    }
    
    return await stripe.paymentIntents.create(paymentIntentParams);
  } catch (err) {
    console.error("Stripe error:", err);
    throw err;
  }
}
