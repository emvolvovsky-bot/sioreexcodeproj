import Stripe from "stripe";

const stripeSecretKey = process.env.STRIPE_SECRET_KEY;

if (!stripeSecretKey) {
  console.warn("STRIPE_SECRET_KEY is not configured; Stripe calls will fail.");
}

const stripe = new Stripe(stripeSecretKey || "missing");

export default stripe;

