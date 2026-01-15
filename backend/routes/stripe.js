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

module.exports = router;

