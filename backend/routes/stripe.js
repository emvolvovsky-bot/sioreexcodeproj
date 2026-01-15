const express = require('express');
const stripe = require('../lib/stripe');

const router = express.Router();

router.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, hostStripeAccountId } = req.body;
    const parsedAmount = Number(amount);

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    if (!hostStripeAccountId) {
      return res.status(400).json({ error: 'hostStripeAccountId is required' });
    }

    const applicationFeeAmount = Math.round(parsedAmount * 0.015);

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(parsedAmount),
      currency: 'usd',
      application_fee_amount: applicationFeeAmount,
      transfer_data: {
        destination: hostStripeAccountId
      }
    });

    return res.json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    console.error('Stripe create-payment-intent error:', error);
    return res.status(500).json({ error: error.message });
  }
});

router.post('/payment-sheet', async (req, res) => {
  try {
    if (!process.env.STRIPE_SECRET_KEY || !process.env.STRIPE_PUBLISHABLE_KEY) {
      return res.status(500).json({ error: 'Stripe keys are not configured' });
    }

    const { amount, currency = 'usd' } = req.body;
    const parsedAmount = Number(amount);

    if (!Number.isFinite(parsedAmount) || parsedAmount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    const customer = await stripe.customers.create();
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customer.id },
      { apiVersion: '2023-10-16' }
    );
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(parsedAmount * 100),
      currency,
      customer: customer.id,
      automatic_payment_methods: { enabled: true }
    });

    return res.json({
      paymentIntent: paymentIntent.client_secret,
      customer: customer.id,
      ephemeralKey: ephemeralKey.secret,
      publishableKey: process.env.STRIPE_PUBLISHABLE_KEY
    });
  } catch (error) {
    console.error('Stripe payment-sheet error:', error);
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;

