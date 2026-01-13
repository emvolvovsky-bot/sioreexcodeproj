const express = require('express');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// GET /api/tickets/my-tickets
// Get tickets purchased by the current user
router.get('/my-tickets', async (req, res) => {
  try {
    const result = await query(`
      SELECT
        t.*,
        e.title as event_title,
        e.date as event_date,
        e.location as event_location,
        e.ticket_price,
        u.name as host_name
      FROM tickets t
      JOIN events e ON t.event_id = e.id
      JOIN users u ON e.host_id = u.id
      WHERE t.buyer_id = $1
      ORDER BY t.created_at DESC
    `, [req.user.id]);

    const tickets = result.rows.map(row => ({
      id: row.id,
      eventId: row.event_id,
      buyerId: row.buyer_id,
      quantity: parseInt(row.quantity),
      ticketAmountCents: parseInt(row.ticket_amount_cents),
      feesAmountCents: parseInt(row.fees_amount_cents),
      totalAmountCents: parseInt(row.total_amount_cents),
      stripePaymentIntentId: row.stripe_payment_intent_id,
      stripeChargeId: row.stripe_charge_id,
      status: row.status,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      // Additional event info
      eventTitle: row.event_title,
      eventDate: row.event_date,
      eventLocation: row.event_location,
      ticketPrice: parseFloat(row.ticket_price || 0),
      hostName: row.host_name,
    }));

    res.json(tickets);
  } catch (error) {
    console.error('Get my tickets error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/tickets/event/:eventId
// Get tickets for an event (host only)
router.get('/event/:eventId', async (req, res) => {
  try {
    const { eventId } = req.params;

    // Verify user is the host of this event
    const eventCheck = await query(
      'SELECT host_id FROM events WHERE id = $1',
      [eventId]
    );

    if (eventCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Event not found' });
    }

    if (eventCheck.rows[0].host_id !== req.user.id) {
      return res.status(403).json({ error: 'Only event host can view tickets' });
    }

    const result = await query(`
      SELECT
        t.*,
        u.name as buyer_name,
        u.email as buyer_email
      FROM tickets t
      JOIN users u ON t.buyer_id = u.id
      WHERE t.event_id = $1
      ORDER BY t.created_at DESC
    `, [eventId]);

    const tickets = result.rows.map(row => ({
      id: row.id,
      eventId: row.event_id,
      buyerId: row.buyer_id,
      quantity: parseInt(row.quantity),
      ticketAmountCents: parseInt(row.ticket_amount_cents),
      feesAmountCents: parseInt(row.fees_amount_cents),
      totalAmountCents: parseInt(row.total_amount_cents),
      stripePaymentIntentId: row.stripe_payment_intent_id,
      stripeChargeId: row.stripe_charge_id,
      status: row.status,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      // Buyer info
      buyerName: row.buyer_name,
      buyerEmail: row.buyer_email,
    }));

    res.json(tickets);
  } catch (error) {
    console.error('Get event tickets error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/tickets/:ticketId/validate
// Validate a ticket for check-in (host only)
router.post('/:ticketId/validate', async (req, res) => {
  try {
    const { ticketId } = req.params;

    // Get ticket and verify user is the host
    const ticketResult = await query(`
      SELECT t.*, e.host_id
      FROM tickets t
      JOIN events e ON t.event_id = e.id
      WHERE t.id = $1
    `, [ticketId]);

    if (ticketResult.rows.length === 0) {
      return res.status(404).json({ error: 'Ticket not found' });
    }

    const ticket = ticketResult.rows[0];

    if (ticket.host_id !== req.user.id) {
      return res.status(403).json({ error: 'Only event host can validate tickets' });
    }

    if (ticket.status !== 'paid') {
      return res.status(400).json({ error: 'Ticket is not valid for check-in' });
    }

    // Mark ticket as used (you might want to add a check-in timestamp field)
    // For now, just return success

    res.json({
      valid: true,
      ticket: {
        id: ticket.id,
        eventId: ticket.event_id,
        buyerId: ticket.buyer_id,
        quantity: parseInt(ticket.quantity),
        status: ticket.status,
      },
    });
  } catch (error) {
    console.error('Validate ticket error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
