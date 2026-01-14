const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// POST /api/payments/create-intent
router.post('/create-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd', description, metadata } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }
    
    // Create Stripe Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: currency,
      description: description || 'Sioree Payment',
      metadata: {
        userId: req.user.id,
        ...metadata,
      },
      automatic_payment_methods: {
        enabled: true,
      },
    });
    
    res.json({
      paymentIntent: {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      },
    });
  } catch (error) {
    console.error('Stripe payment intent error:', error);
    res.status(500).json({ error: 'Failed to create payment intent' });
  }
});

// POST /api/payments/create-method
router.post('/create-method', async (req, res) => {
  try {
    const { paymentMethodId } = req.body;

    if (!paymentMethodId) {
      return res.status(400).json({ error: 'Payment method ID required' });
    }

    // Retrieve the payment method from Stripe to get its details
    const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);

    // Attach payment method to customer (create customer if needed)
    // In production, you'd want to create/retrieve a Stripe customer for the user
    let customer;
    try {
      // Try to find existing customer by email
      const customers = await stripe.customers.list({
        email: req.user.email,
        limit: 1
      });

      if (customers.data.length > 0) {
        customer = customers.data[0];
      } else {
        // Create new customer
        customer = await stripe.customers.create({
          email: req.user.email,
          metadata: { userId: req.user.id }
        });
      }
    } catch (customerError) {
      console.error('Customer creation error:', customerError);
      return res.status(500).json({ error: 'Failed to create customer' });
    }

    // Attach payment method to customer
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customer.id,
    });

    // Return payment method details
    res.json({
      paymentMethod: {
        id: paymentMethod.id,
        type: paymentMethod.type,
        card: paymentMethod.card ? {
          brand: paymentMethod.card.brand,
          last4: paymentMethod.card.last4,
          expMonth: paymentMethod.card.exp_month,
          expYear: paymentMethod.card.exp_year,
        } : null,
      },
    });
  } catch (error) {
    console.error('Stripe payment method error:', error);
    res.status(500).json({ error: 'Failed to create payment method' });
  }
});

// POST /api/payments/confirm
router.post('/confirm', async (req, res) => {
  try {
    const { paymentIntentId, paymentMethodId } = req.body;
    
    if (!paymentIntentId || !paymentMethodId) {
      return res.status(400).json({ error: 'Missing payment details' });
    }
    
    // Confirm payment intent
    const paymentIntent = await stripe.paymentIntents.confirm(paymentIntentId, {
      payment_method: paymentMethodId,
    });
    
    if (paymentIntent.status === 'succeeded') {
      // Save payment to database
      const result = await query(
        `INSERT INTO payments 
         (user_id, amount, method, status, transaction_id, description, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, NOW())
         RETURNING id, user_id, amount, method, status, transaction_id, description, created_at`,
        [
          req.user.id,
          paymentIntent.amount / 100, // Convert from cents
          'credit_card',
          'paid',
          paymentIntent.id,
          paymentIntent.description || 'Sioree Payment',
        ]
      );
      
      const payment = result.rows[0];
      
      // Update booking payment status if bookingId exists
      if (paymentIntent.metadata?.booking_id) {
        await query(
          `UPDATE bookings 
           SET payment_status = 'paid', status = 'confirmed'
           WHERE id = $1`,
          [paymentIntent.metadata.booking_id]
        );
      }
      
      res.json({
        id: payment.id,
        userId: payment.user_id,
        amount: parseFloat(payment.amount),
        method: payment.method,
        status: payment.status,
        transactionId: payment.transaction_id,
        description: payment.description,
        createdAt: payment.created_at,
      });
    } else {
      res.status(400).json({ error: 'Payment not completed' });
    }
  } catch (error) {
    console.error('Stripe confirm payment error:', error);
    res.status(500).json({ error: 'Failed to confirm payment' });
  }
});

// POST /api/payments/confirm-apple-pay
router.post('/confirm-apple-pay', async (req, res) => {
  try {
    const { paymentIntentId } = req.body;
    
    if (!paymentIntentId) {
      return res.status(400).json({ error: 'Missing payment intent ID' });
    }
    
    // Retrieve payment intent
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    if (paymentIntent.status === 'succeeded') {
      // Save payment to database
      const result = await query(
        `INSERT INTO payments 
         (user_id, amount, method, status, transaction_id, description, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, NOW())
         RETURNING id, user_id, amount, method, status, transaction_id, description, created_at`,
        [
          req.user.id,
          paymentIntent.amount / 100,
          'apple_pay',
          'paid',
          paymentIntent.id,
          paymentIntent.description || 'Sioree Payment',
        ]
      );
      
      const payment = result.rows[0];
      
      // Update booking payment status if bookingId exists
      if (paymentIntent.metadata?.booking_id) {
        await query(
          `UPDATE bookings 
           SET payment_status = 'paid', status = 'confirmed'
           WHERE id = $1`,
          [paymentIntent.metadata.booking_id]
        );
      }
      
      res.json({
        id: payment.id,
        userId: payment.user_id,
        amount: parseFloat(payment.amount),
        method: payment.method,
        status: payment.status,
        transactionId: payment.transaction_id,
        description: payment.description,
        createdAt: payment.created_at,
      });
    } else {
      res.status(400).json({ error: 'Payment not completed' });
    }
  } catch (error) {
    console.error('Apple Pay confirm error:', error);
    res.status(500).json({ error: 'Failed to confirm Apple Pay payment' });
  }
});

// GET /api/payments
router.get('/', async (req, res) => {
  try {
    const result = await query(
      `SELECT id, user_id, amount, method, status, transaction_id, description, created_at
       FROM payments
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.user.id]
    );
    
    const payments = result.rows.map(row => ({
      id: row.id,
      userId: row.user_id,
      amount: parseFloat(row.amount),
      method: row.method,
      status: row.status,
      transactionId: row.transaction_id,
      description: row.description,
      createdAt: row.created_at,
    }));
    
    res.json(payments);
  } catch (error) {
    console.error('Get payments error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/payments/save-method
router.post('/save-method', async (req, res) => {
  try {
    const { paymentMethodId, setAsDefault } = req.body;
    
    // Attach payment method to customer
    // In production, create/retrieve Stripe customer for user
    const customer = await stripe.customers.create({
      email: req.user.email,
      metadata: { userId: req.user.id },
    });
    
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: customer.id,
    });
    
    if (setAsDefault) {
      await stripe.customers.update(customer.id, {
        invoice_settings: {
          default_payment_method: paymentMethodId,
        },
      });
    }
    
    res.json({ success: true });
  } catch (error) {
    console.error('Save payment method error:', error);
    res.status(500).json({ error: 'Failed to save payment method' });
  }
});

// GET /api/payments/methods
router.get('/methods', async (req, res) => {
  try {
    // In production, retrieve customer's payment methods
    // For now, return empty array
    res.json({ paymentMethods: [] });
  } catch (error) {
    console.error('Get payment methods error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/payments/methods/:paymentMethodId
router.delete('/methods/:paymentMethodId', async (req, res) => {
  try {
    const { paymentMethodId } = req.params;
    
    await stripe.paymentMethods.detach(paymentMethodId);
    
    res.json({ success: true });
  } catch (error) {
    console.error('Delete payment method error:', error);
    res.status(500).json({ error: 'Failed to delete payment method' });
  }
});

// POST /api/payments/create-setup-intent
router.post('/create-setup-intent', async (req, res) => {
  try {
    // Create a SetupIntent for saving payment methods
    const setupIntent = await stripe.setupIntents.create({
      payment_method_types: ['card'],
      usage: 'off_session', // Allows using saved payment methods later
    });

    res.json({
      clientSecret: setupIntent.client_secret,
      setupIntentId: setupIntent.id,
    });
  } catch (error) {
    console.error('Stripe setup intent error:', error);
    res.status(500).json({ error: 'Failed to create setup intent' });
  }
});

module.exports = router;


