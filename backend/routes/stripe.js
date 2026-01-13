const express = require('express');
const stripe = process.env.STRIPE_SECRET_KEY ? require('stripe')(process.env.STRIPE_SECRET_KEY) : null;
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// Helper function to check if user is a host
const requireHost = async (req, res, next) => {
  try {
    const result = await query('SELECT role FROM users WHERE id = $1', [req.user.id]);
    if (result.rows.length === 0 || result.rows[0].role !== 'host') {
      return res.status(403).json({ error: 'Host access required' });
    }
    next();
  } catch (error) {
    console.error('Error checking host role:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/stripe/connect/create-account
// Create a Stripe Connect account for the host
router.post('/connect/create-account', requireHost, async (req, res) => {
  if (!stripe) {
    return res.status(500).json({ error: 'Stripe payment system not configured' });
  }
  try {
    // Check if host already has a connected account
    const existingAccount = await query(
      'SELECT stripe_account_id FROM users WHERE id = $1 AND stripe_account_id IS NOT NULL',
      [req.user.id]
    );

    if (existingAccount.rows.length > 0) {
      return res.status(400).json({ error: 'Stripe account already exists' });
    }

    // Create a Stripe Connect Express account
    const account = await stripe.accounts.create({
      type: 'express',
      country: 'US', // Default to US, can be made configurable
      email: req.user.email,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      business_type: 'individual', // Can be made configurable based on host type
      metadata: {
        userId: req.user.id,
      },
    });

    // Store the account ID in our database
    await query(
      'UPDATE users SET stripe_account_id = $1 WHERE id = $2',
      [account.id, req.user.id]
    );

    console.log(`Created Stripe Connect account for host ${req.user.id}: ${account.id}`);

    res.json({
      account_id: account.id,
      success: true,
    });
  } catch (error) {
    console.error('Stripe create account error:', error);
    res.status(500).json({ error: 'Failed to create Stripe account' });
  }
});

// POST /api/stripe/connect/create-account-link
// Create an onboarding link for the host to complete verification
router.post('/connect/create-account-link', requireHost, async (req, res) => {
  if (!stripe) {
    return res.status(500).json({ error: 'Stripe payment system not configured' });
  }
  try {
    // Get the host's Stripe account ID
    const result = await query(
      'SELECT stripe_account_id FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0 || !result.rows[0].stripe_account_id) {
      return res.status(400).json({ error: 'Stripe account not found. Please create an account first.' });
    }

    const accountId = result.rows[0].stripe_account_id;

    // Create an account link for onboarding
    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: `${process.env.FRONTEND_URL || 'https://sioree.com'}/host/onboarding?refresh=true`,
      return_url: `${process.env.FRONTEND_URL || 'https://sioree.com'}/host/dashboard`,
      type: 'account_onboarding',
    });

    // Store the URLs for reference
    await query(
      'UPDATE users SET stripe_onboarding_url = $1, stripe_refresh_url = $2 WHERE id = $3',
      [accountLink.url, accountLink.refresh_url || accountLink.url, req.user.id]
    );

    console.log(`Created onboarding link for host ${req.user.id}: ${accountLink.url}`);

    res.json({
      url: accountLink.url,
      expires_at: accountLink.expires_at,
    });
  } catch (error) {
    console.error('Stripe create account link error:', error);
    res.status(500).json({ error: 'Failed to create onboarding link' });
  }
});

// GET /api/stripe/connect/status
// Check the status of the host's Stripe Connect account
router.get('/connect/status', requireHost, async (req, res) => {
  if (!stripe) {
    return res.status(500).json({ error: 'Stripe payment system not configured' });
  }
  try {
    // Get the host's Stripe account ID
    const result = await query(
      'SELECT stripe_account_id, stripe_charges_enabled, stripe_payouts_enabled FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0 || !result.rows[0].stripe_account_id) {
      return res.json({
        onboarding_complete: false,
        charges_enabled: false,
        payouts_enabled: false,
        needs_onboarding: true,
      });
    }

    const accountId = result.rows[0].stripe_account_id;

    // Retrieve the account from Stripe to get current status
    const account = await stripe.accounts.retrieve(accountId);

    const chargesEnabled = account.capabilities?.card_payments === 'active';
    const payoutsEnabled = account.capabilities?.transfers === 'active';
    const onboardingComplete = chargesEnabled && payoutsEnabled;

    // Update our database with the latest status
    await query(
      'UPDATE users SET stripe_charges_enabled = $1, stripe_payouts_enabled = $2, stripe_onboarding_complete = $3 WHERE id = $4',
      [chargesEnabled, payoutsEnabled, onboardingComplete, req.user.id]
    );

    console.log(`Updated Stripe status for host ${req.user.id}: charges=${chargesEnabled}, payouts=${payoutsEnabled}`);

    res.json({
      onboarding_complete: onboardingComplete,
      charges_enabled: chargesEnabled,
      payouts_enabled: payoutsEnabled,
      needs_onboarding: !onboardingComplete,
      account_id: accountId,
    });
  } catch (error) {
    console.error('Stripe status check error:', error);
    res.status(500).json({ error: 'Failed to check account status' });
  }
});

// POST /api/stripe/checkout/create-payment-intent
// Create a payment intent for ticket purchase with Stripe Connect
router.post('/checkout/create-payment-intent', authenticate, async (req, res) => {
  if (!stripe) {
    return res.status(500).json({ error: 'Stripe payment system not configured' });
  }
  try {
    const { event_id, quantity = 1 } = req.body;

    if (!event_id || quantity < 1) {
      return res.status(400).json({ error: 'Invalid event_id or quantity' });
    }

    // Get event details and verify host has completed onboarding
    const eventResult = await query(`
      SELECT e.*, u.stripe_account_id, u.stripe_onboarding_complete
      FROM events e
      JOIN users u ON e.host_id = u.id
      WHERE e.id = $1 AND e.status = 'published'
    `, [event_id]);

    if (eventResult.rows.length === 0) {
      return res.status(404).json({ error: 'Event not found or not published' });
    }

    const event = eventResult.rows[0];

    if (!event.stripe_onboarding_complete || !event.stripe_account_id) {
      return res.status(400).json({ error: 'Host has not completed payment setup' });
    }

    const ticketPriceCents = event.ticket_price_cents || Math.round(event.ticket_price * 100);
    const platformFeeBps = event.platform_fee_bps || 200; // 2%

    // Calculate amounts
    const ticketAmount = ticketPriceCents * quantity;
    const feesAmount = Math.round(ticketAmount * (platformFeeBps / 10000)); // Convert bps to decimal
    const totalAmount = ticketAmount + feesAmount;

    // Create PaymentIntent with Stripe Connect
    const paymentIntent = await stripe.paymentIntents.create({
      amount: totalAmount,
      currency: 'usd',
      description: `Tickets for ${event.title}`,
      automatic_payment_methods: {
        enabled: true, // This enables Apple Pay, Google Pay, etc.
      },
      transfer_data: {
        destination: event.stripe_account_id,
        amount: ticketAmount, // Only transfer the ticket amount, not including platform fees
      },
      application_fee_amount: feesAmount,
      metadata: {
        event_id: event_id,
        host_id: event.host_id,
        buyer_id: req.user.id,
        quantity: quantity,
        ticket_amount_cents: ticketAmount,
        fees_amount_cents: feesAmount,
        platform_fee_bps: platformFeeBps,
      },
    });

    console.log(`Created payment intent for event ${event_id}: ${paymentIntent.id}, amount: ${totalAmount} cents`);

    res.json({
      paymentIntent: {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      },
      pricing: {
        ticket_price_cents: ticketPriceCents,
        quantity: quantity,
        ticket_amount_cents: ticketAmount,
        fees_amount_cents: feesAmount,
        total_amount_cents: totalAmount,
        platform_fee_percentage: (platformFeeBps / 100).toFixed(2),
      },
    });
  } catch (error) {
    console.error('Stripe create payment intent error:', error);
    res.status(500).json({ error: 'Failed to create payment intent' });
  }
});

// POST /api/stripe/webhook
// Handle Stripe webhooks for payment confirmations
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  if (!stripe) {
    console.error('Stripe webhook received but Stripe not configured');
    return res.status(500).json({ error: 'Stripe payment system not configured' });
  }
  const sig = req.headers['stripe-signature'];
  const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, endpointSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Check if we've already processed this event
  const existingEvent = await query(
    'SELECT id FROM stripe_webhook_events WHERE event_id = $1',
    [event.id]
  );

  if (existingEvent.rows.length > 0) {
    console.log(`Webhook event ${event.id} already processed`);
    return res.json({ received: true });
  }

  // Store the event
  await query(
    'INSERT INTO stripe_webhook_events (event_id, event_type, data) VALUES ($1, $2, $3)',
    [event.id, event.type, JSON.stringify(event.data)]
  );

  try {
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentIntentSucceeded(event.data.object);
        break;

      case 'payment_intent.payment_failed':
        await handlePaymentIntentFailed(event.data.object);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    // Mark event as processed
    await query(
      'UPDATE stripe_webhook_events SET processed = true, processed_at = NOW() WHERE event_id = $1',
      [event.id]
    );

    res.json({ received: true });
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

// Helper function to handle successful payments
async function handlePaymentIntentSucceeded(paymentIntent) {
  const {
    event_id,
    host_id,
    buyer_id,
    quantity,
    ticket_amount_cents,
    fees_amount_cents,
  } = paymentIntent.metadata;

  console.log(`Processing successful payment for event ${event_id}, buyer ${buyer_id}`);

  // Create ticket records
  for (let i = 0; i < parseInt(quantity); i++) {
    await query(`
      INSERT INTO tickets
      (event_id, buyer_id, quantity, ticket_amount_cents, fees_amount_cents, total_amount_cents, stripe_payment_intent_id, stripe_charge_id)
      VALUES ($1, $2, 1, $3, $4, $5, $6, $7)
    `, [
      event_id,
      buyer_id,
      ticket_amount_cents / parseInt(quantity), // Per ticket amount
      fees_amount_cents / parseInt(quantity), // Per ticket fees
      (parseInt(ticket_amount_cents) + parseInt(fees_amount_cents)) / parseInt(quantity), // Per ticket total
      paymentIntent.id,
      paymentIntent.charges.data[0]?.id,
    ]);
  }

  console.log(`Created ${quantity} ticket(s) for event ${event_id}`);
}

// Helper function to handle failed payments
async function handlePaymentIntentFailed(paymentIntent) {
  const { event_id, buyer_id } = paymentIntent.metadata;

  console.log(`Payment failed for event ${event_id}, buyer ${buyer_id}`);

  // Here you could mark any pending tickets as failed, send notifications, etc.
  // For now, just log it
}

module.exports = router;
