import Stripe from "stripe";

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "");

export async function createPaymentIntent(amount, hostStripeAccountId) {
  try {
    // Convert amount to cents (Stripe uses smallest currency unit)
    const amountInCents = Math.round(amount * 100);
    
    // IMPORTANT: Cannot use both payment_method_types and automatic_payment_methods together
    // Using only automatic_payment_methods which enables all available payment methods
    const paymentIntentParams = {
      amount: amountInCents,
      currency: "usd",
      automatic_payment_methods: {
        enabled: true
      }
      // NOTE: payment_method_types is NOT included here to avoid Stripe error
    };
    
    // Only add transfer_data if hostStripeAccountId is provided and not empty (for bookings)
    // This should only be used for marketplace payments where we need to transfer to a connected account
    if (hostStripeAccountId && typeof hostStripeAccountId === 'string' && hostStripeAccountId.trim() !== '') {
      paymentIntentParams.transfer_data = {
        destination: hostStripeAccountId,
        amount: Math.floor(amountInCents * 0.9) // 10% platform fee
      };
    }
    
    return await stripe.paymentIntents.create(paymentIntentParams);
  } catch (err) {
    console.error("Stripe error:", err);
    throw err;
  }
}
