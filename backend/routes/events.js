const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /api/events (public, no auth required)
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    
    let whereClause = 'WHERE 1=1';
    const params = [];
    let paramIndex = 1;
    
    if (req.query.location) {
      params.push(`%${req.query.location}%`);
      whereClause += ` AND location ILIKE $${paramIndex}`;
      paramIndex++;
    }
    
    if (req.query.date) {
      params.push(req.query.date);
      whereClause += ` AND DATE(date) = $${paramIndex}`;
      paramIndex++;
    }
    
    if (req.query.search) {
      params.push(`%${req.query.search}%`);
      whereClause += ` AND (title ILIKE $${paramIndex} OR description ILIKE $${paramIndex})`;
      paramIndex++;
    }
    
    params.push(limit, offset);
    
    const result = await query(
      `SELECT 
        e.id,
        e.host_id,
        e.title,
        e.description,
        e.date,
        e.location,
        e.latitude,
        e.longitude,
        e.ticket_price,
        e.capacity,
        e.tags,
        e.is_featured,
        e.images,
        u.name as host_name
      FROM events e
      JOIN users u ON e.host_id = u.id
      ${whereClause}
      ORDER BY e.is_featured DESC, e.date ASC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      params
    );
    
    const countResult = await query(
      `SELECT COUNT(*) FROM events e ${whereClause}`,
      params.slice(0, -2) // Remove limit and offset
    );
    
    const events = result.rows.map(row => ({
      id: row.id,
      hostId: row.host_id,
      title: row.title,
      hostName: row.host_name,
      date: row.date,
      location: row.location,
      priceText: row.ticket_price ? `$${row.ticket_price}` : 'Free',
      imageName: 'party.popper.fill', // Default, can be determined from tags
      tags: row.tags || [],
      isFeatured: row.is_featured,
      images: row.images || [],
    }));
    
    res.json({
      events,
      total: parseInt(countResult.rows[0].count),
      page,
      limit,
    });
  } catch (error) {
    console.error('Get events error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/events (requires auth)
router.post('/', authenticate, [
  body('title').trim().notEmpty(),
  body('description').optional().trim(),
  body('date').isISO8601(),
  body('location').trim().notEmpty(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const {
      title,
      description,
      date,
      location,
      latitude,
      longitude,
      ticketPrice,
      capacity,
      tags,
      isFeatured,
      images,
    } = req.body;
    
    const result = await query(
      `INSERT INTO events 
       (host_id, title, description, date, location, latitude, longitude, ticket_price, capacity, tags, is_featured, images, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), NOW())
       RETURNING id, host_id, title, date, location, created_at`,
      [
        req.user.id,
        title,
        description || null,
        date,
        location,
        latitude || null,
        longitude || null,
        ticketPrice || null,
        capacity || null,
        tags || [],
        isFeatured || false,
        images || [],
      ]
    );
    
    const event = result.rows[0];
    
    res.status(201).json({
      id: event.id,
      hostId: event.host_id,
      title: event.title,
      date: event.date,
      location: event.location,
      createdAt: event.created_at,
    });
  } catch (error) {
    console.error('Create event error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/events/:eventId/attendees
router.get('/:eventId/attendees', async (req, res) => {
  try {
    const { eventId } = req.params;
    
    const result = await query(
      `SELECT 
        u.id,
        u.name,
        u.email as username,
        u.avatar_url,
        ea.status
      FROM event_attendees ea
      JOIN users u ON ea.user_id = u.id
      WHERE ea.event_id = $1 AND ea.status = 'going'
      ORDER BY ea.created_at DESC`,
      [eventId]
    );
    
    const attendees = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      username: `@${row.email.split('@')[0]}`,
      avatar: row.avatar_url,
      isVerified: false, // Can add verification field later
    }));
    
    res.json({ attendees });
  } catch (error) {
    console.error('Get attendees error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;



