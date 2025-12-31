const express = require('express');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// GET /api/bookings - Get user's bookings (different behavior for host vs talent)
router.get('/', async (req, res) => {
  try {
    let bookingsQuery;
    let params;

    if (req.user.user_type === 'host') {
      // Hosts see bookings they've made for talent
      bookingsQuery = `
        SELECT
          b.*,
          t.name as talent_name,
          t.avatar as talent_avatar,
          t.category as talent_category,
          e.title as event_title,
          e.location as event_location,
          e.event_date as event_date
        FROM bookings b
        LEFT JOIN talent t ON b.talent_id = t.id
        LEFT JOIN events e ON b.event_id = e.id
        WHERE b.host_id = $1
        ORDER BY b.created_at DESC
      `;
      params = [req.user.id];
    } else {
      // Talent see bookings they've received
      bookingsQuery = `
        SELECT
          b.*,
          u.name as host_name,
          u.avatar as host_avatar,
          e.title as event_title,
          e.location as event_location,
          e.event_date as event_date
        FROM bookings b
        LEFT JOIN users u ON b.host_id = u.id
        LEFT JOIN events e ON b.event_id = e.id
        WHERE b.talent_id = $1
        ORDER BY b.created_at DESC
      `;
      params = [req.user.id];
    }

    const result = await query(bookingsQuery, params);

    const bookings = result.rows.map(row => ({
      id: row.id,
      eventId: row.event_id,
      talentId: row.talent_id,
      hostId: row.host_id,
      date: row.date,
      duration: row.duration,
      price: parseFloat(row.price),
      status: row.status,
      paymentStatus: row.payment_status,
      notes: row.notes,
      createdAt: row.created_at,
      // Additional fields based on user type
      talent: req.user.user_type === 'host' ? {
        name: row.talent_name,
        avatar: row.talent_avatar,
        category: row.talent_category
      } : null,
      host: req.user.user_type !== 'host' ? {
        name: row.host_name,
        avatar: row.host_avatar
      } : null,
      event: {
        title: row.event_title,
        location: row.event_location,
        date: row.event_date
      }
    }));

    res.json(bookings);
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/bookings/event/:eventId - Get bookings for a specific event
router.get('/event/:eventId', async (req, res) => {
  try {
    const { eventId } = req.params;

    // Check if user is the host of this event
    const eventResult = await query(
      'SELECT creator_id FROM events WHERE id = $1',
      [eventId]
    );

    if (eventResult.rows.length === 0) {
      return res.status(404).json({ error: 'Event not found' });
    }

    if (eventResult.rows[0].creator_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const result = await query(`
      SELECT
        b.*,
        t.name as talent_name,
        t.avatar as talent_avatar,
        t.category as talent_category,
        t.bio as talent_bio,
        t.rating as talent_rating,
        t.review_count as talent_review_count
      FROM bookings b
      LEFT JOIN talent t ON b.talent_id = t.id
      WHERE b.event_id = $1
      ORDER BY b.created_at DESC
    `, [eventId]);

    const bookings = result.rows.map(row => ({
      id: row.id,
      eventId: row.event_id,
      talentId: row.talent_id,
      hostId: row.host_id,
      date: row.date,
      duration: row.duration,
      price: parseFloat(row.price),
      status: row.status,
      paymentStatus: row.payment_status,
      notes: row.notes,
      createdAt: row.created_at,
      talent: {
        name: row.talent_name,
        avatar: row.talent_avatar,
        category: row.talent_category,
        bio: row.talent_bio,
        rating: parseFloat(row.talent_rating),
        reviewCount: row.talent_review_count
      }
    }));

    res.json(bookings);
  } catch (error) {
    console.error('Get event bookings error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/bookings - Create a new booking request
router.post('/', async (req, res) => {
  try {
    const { eventId, talentId, date, duration, price, notes } = req.body;

    if (!eventId || !talentId || !date || !price) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Verify the event exists and user is the host
    const eventResult = await query(
      'SELECT creator_id FROM events WHERE id = $1',
      [eventId]
    );

    if (eventResult.rows.length === 0) {
      return res.status(404).json({ error: 'Event not found' });
    }

    if (eventResult.rows[0].creator_id !== req.user.id) {
      return res.status(403).json({ error: 'Only event hosts can create bookings' });
    }

    // Verify talent exists
    const talentResult = await query(
      'SELECT id FROM talent WHERE id = $1',
      [talentId]
    );

    if (talentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Talent not found' });
    }

    // Create booking
    const result = await query(`
      INSERT INTO bookings (event_id, talent_id, host_id, date, duration, price, status, notes, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, 'requested', $7, NOW())
      RETURNING *
    `, [eventId, talentId, req.user.id, date, duration || 4, price, notes]);

    const booking = result.rows[0];

    // TODO: Send notification to talent

    res.status(201).json({
      id: booking.id,
      eventId: booking.event_id,
      talentId: booking.talent_id,
      hostId: booking.host_id,
      date: booking.date,
      duration: booking.duration,
      price: parseFloat(booking.price),
      status: booking.status,
      notes: booking.notes,
      createdAt: booking.created_at
    });
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/bookings/:id/status - Update booking status
router.put('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    if (!status) {
      return res.status(400).json({ error: 'Status is required' });
    }

    const validStatuses = ['requested', 'accepted', 'awaiting_payment', 'confirmed', 'declined', 'expired', 'canceled', 'completed'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    // Get booking and verify permissions
    const bookingResult = await query(
      'SELECT * FROM bookings WHERE id = $1',
      [id]
    );

    if (bookingResult.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = bookingResult.rows[0];
    const isHost = booking.host_id === req.user.id;
    const isTalent = booking.talent_id === req.user.id;

    if (!isHost && !isTalent) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Validate status transitions based on user role
    if (isTalent) {
      // Talent can only change status from 'requested' to 'accepted' or 'declined'
      if (booking.status !== 'requested') {
        return res.status(400).json({ error: 'Talent can only respond to requested bookings' });
      }
      if (!['accepted', 'declined'].includes(status)) {
        return res.status(400).json({ error: 'Talent can only accept or decline requests' });
      }
    } else if (isHost) {
      // Host can change status based on current state
      const allowedTransitions = {
        'requested': ['canceled'],
        'accepted': ['awaiting_payment', 'canceled'],
        'awaiting_payment': ['confirmed', 'canceled'],
        'confirmed': ['completed', 'canceled'],
        'declined': [],
        'expired': [],
        'canceled': [],
        'completed': []
      };

      if (!allowedTransitions[booking.status]?.includes(status)) {
        return res.status(400).json({ error: 'Invalid status transition' });
      }
    }

    // Update booking status
    const updateResult = await query(`
      UPDATE bookings
      SET status = $1, notes = COALESCE($3, notes), updated_at = NOW()
      WHERE id = $2
      RETURNING *
    `, [status, id, notes]);

    const updatedBooking = updateResult.rows[0];

    // TODO: Send notification about status change

    res.json({
      id: updatedBooking.id,
      status: updatedBooking.status,
      notes: updatedBooking.notes,
      updatedAt: updatedBooking.updated_at
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/bookings/:id - Cancel/delete booking (for hosts only)
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Get booking and verify user is the host
    const bookingResult = await query(
      'SELECT host_id, status FROM bookings WHERE id = $1',
      [id]
    );

    if (bookingResult.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = bookingResult.rows[0];

    if (booking.host_id !== req.user.id) {
      return res.status(403).json({ error: 'Only hosts can delete bookings' });
    }

    // Only allow deletion of bookings that haven't been accepted yet
    if (booking.status !== 'requested') {
      return res.status(400).json({ error: 'Cannot delete booking that has been accepted' });
    }

    await query('DELETE FROM bookings WHERE id = $1', [id]);

    res.json({ success: true });
  } catch (error) {
    console.error('Delete booking error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
