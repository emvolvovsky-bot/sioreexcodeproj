// Payment services are not implemented
export async function createPaymentIntent(amount, hostStripeAccountId) {
  throw new Error("Payment processing is not implemented");
}

export async function createPaymentMethod(cardDetails) {
  throw new Error("Payment processing is not implemented");
}

export async function confirmPaymentIntent(paymentIntentId, paymentMethodId) {
  throw new Error("Payment processing is not implemented");
}

export default null;
