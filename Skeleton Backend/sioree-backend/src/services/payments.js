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

export async function createPaymentMethod(cardDetails) {
  try {
    const { number, exp_month, exp_year, cvc, zip } = cardDetails;
    
    const paymentMethod = await stripe.paymentMethods.create({
      type: "card",
      card: {
        number: number,
        exp_month: exp_month,
        exp_year: exp_year,
        cvc: cvc
      },
      billing_details: {
        address: {
          postal_code: zip
        }
      }
    });
    
    return {
      id: paymentMethod.id,
      type: paymentMethod.type,
      card: paymentMethod.card ? {
        brand: paymentMethod.card.brand,
        last4: paymentMethod.card.last4,
        expMonth: paymentMethod.card.exp_month,
        expYear: paymentMethod.card.exp_year
      } : null
    };
  } catch (err) {
    console.error("Stripe create payment method error:", err);
    throw err;
  }
}

export async function confirmPaymentIntent(paymentIntentId, paymentMethodId) {
  try {
    const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId, {
      payment_method: paymentMethodId
    });
    
    return paymentIntent;
  } catch (err) {
    console.error("Stripe confirm payment intent error:", err);
    throw err;
  }
}
