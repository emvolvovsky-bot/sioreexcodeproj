const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Store io instance for socket broadcasting
let io;

function setSocketIO(socketIO) {
  io = socketIO;
}

module.exports.setSocketIO = setSocketIO;

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

// GET /api/events/featured (public, no auth required)
router.get('/featured', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

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
      WHERE e.is_featured = true
      ORDER BY e.date ASC
      LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    const countResult = await query(
      `SELECT COUNT(*) FROM events e WHERE e.is_featured = true`,
      []
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
    console.error('Get featured events error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/events/nearby (public, no auth required)
router.get('/nearby', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const lat = parseFloat(req.query.lat);
    const lng = parseFloat(req.query.lng);
    const radius = parseInt(req.query.radius) || 30;

    if (isNaN(lat) || isNaN(lng)) {
      return res.status(400).json({ error: 'Latitude and longitude are required' });
    }

    // Calculate distance using PostGIS or simple approximation
    // For now, using simple bounding box approximation
    const latDiff = radius / 69.0; // 1 degree latitude ≈ 69 miles
    const lngDiff = radius / (69.0 * Math.cos(lat * Math.PI / 180.0));

    const minLat = lat - latDiff;
    const maxLat = lat + latDiff;
    const minLng = lng - lngDiff;
    const maxLng = lng + lngDiff;

    let whereClause = `
      WHERE e.latitude BETWEEN $1 AND $2
      AND e.longitude BETWEEN $3 AND $4
      AND e.is_featured = false
    `;
    const params = [minLat, maxLat, minLng, maxLng];
    let paramIndex = 5;

    if (req.query.date) {
      params.push(req.query.date);
      whereClause += ` AND DATE(e.date) = $${paramIndex}`;
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
      ORDER BY e.date ASC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      params
    );

    const countResult = await query(
      `SELECT COUNT(*) FROM events e ${whereClause.replace('LIMIT $' + paramIndex + ' OFFSET $' + (paramIndex + 1), '')}`,
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
    console.error('Get nearby events error:', error);
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

    // Create a complete event object for the response
    const completeEvent = {
      id: event.id,
      hostId: event.host_id,
      title: event.title,
      hostName: req.user.name, // Include host name from authenticated user
      date: event.date,
      location: event.location,
      latitude: latitude,
      longitude: longitude,
      ticketPrice: ticketPrice,
      capacity: capacity,
      tags: tags || [],
      isFeatured: isFeatured || false,
      images: images || [],
      created_at: event.created_at, // Use snake_case for createdAt
      description: description || '',
      attendees: 0, // Use 'attendees' key as expected by frontend
      talentIds: talentIds || [],
      status: 'published',
      likes: 0,
      isLiked: false,
      isSaved: false,
      isRSVPed: false,
      lookingForRoles: lookingForRoles || [],
      lookingForNotes: lookingForNotes,
      lookingForTalentType: lookingForTalentType,
    };

    // Broadcast new event to all connected clients
    if (io) {
      io.emit('new_event', completeEvent);
    }

    res.status(201).json(completeEvent);
  } catch (error) {
    console.error('Create event error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/events/:id (requires auth, host only)
router.put('/:id', authenticate, [
  body('title').optional().trim().notEmpty(),
  body('description').optional().trim(),
  body('date').optional().isISO8601(),
  body('location').optional().trim().notEmpty(),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    const { id } = req.params;
    const {
      title,
      description,
      date,
      location,
      latitude,
      longitude,
      capacity,
    } = req.body;
    
    // First, verify the event exists and the user is the host
    const eventCheck = await query(
      'SELECT host_id FROM events WHERE id = $1',
      [id]
    );
    
    if (eventCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Event not found' });
    }
    
    if (eventCheck.rows[0].host_id !== req.user.id) {
      return res.status(403).json({ error: 'Only the event host can update this event' });
    }
    
    // Build update query dynamically based on provided fields
    const updates = [];
    const params = [];
    let paramIndex = 1;
    
    if (title !== undefined) {
      updates.push(`title = $${paramIndex}`);
      params.push(title);
      paramIndex++;
    }
    
    if (description !== undefined) {
      updates.push(`description = $${paramIndex}`);
      params.push(description);
      paramIndex++;
    }
    
    if (date !== undefined) {
      updates.push(`date = $${paramIndex}`);
      params.push(date);
      paramIndex++;
    }
    
    if (location !== undefined) {
      updates.push(`location = $${paramIndex}`);
      params.push(location);
      paramIndex++;
    }
    
    if (latitude !== undefined) {
      updates.push(`latitude = $${paramIndex}`);
      params.push(latitude);
      paramIndex++;
    }
    
    if (longitude !== undefined) {
      updates.push(`longitude = $${paramIndex}`);
      params.push(longitude);
      paramIndex++;
    }
    
    if (capacity !== undefined) {
      updates.push(`capacity = $${paramIndex}`);
      params.push(capacity);
      paramIndex++;
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }
    
    // Always update the updated_at timestamp
    updates.push(`updated_at = NOW()`);
    
    params.push(id);
    
    const updateQuery = `
      UPDATE events 
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex}
      RETURNING id, host_id, title, description, date, location, latitude, longitude, ticket_price, capacity, tags, is_featured, images, created_at, updated_at
    `;
    
    const result = await query(updateQuery, params);
    const updatedEvent = result.rows[0];
    
    // Get host name
    const hostResult = await query(
      'SELECT name, username FROM users WHERE id = $1',
      [updatedEvent.host_id]
    );
    const host = hostResult.rows[0];
    
    // Format response similar to create endpoint
    const completeEvent = {
      id: updatedEvent.id,
      hostId: updatedEvent.host_id,
      title: updatedEvent.title,
      hostName: host?.name || host?.username || 'Unknown Host',
      date: updatedEvent.date,
      location: updatedEvent.location,
      latitude: updatedEvent.latitude,
      longitude: updatedEvent.longitude,
      ticketPrice: updatedEvent.ticket_price,
      capacity: updatedEvent.capacity,
      tags: updatedEvent.tags || [],
      isFeatured: updatedEvent.is_featured || false,
      images: updatedEvent.images || [],
      created_at: updatedEvent.created_at,
      description: updatedEvent.description || '',
      attendees: 0,
      status: 'published',
      likes: 0,
      isLiked: false,
      isSaved: false,
      isRSVPed: false,
    };
    
    res.json(completeEvent);
  } catch (error) {
    console.error('Update event error:', error);
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



