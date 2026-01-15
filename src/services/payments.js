// Payment services are not implemented
export async function createPaymentIntent(amount, hostStripeAccountId, metadata = {}) {
  throw new Error("Payment processing is not implemented");
}
