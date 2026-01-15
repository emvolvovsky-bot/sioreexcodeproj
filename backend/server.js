require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { createServer } = require('http');
const { Server } = require('socket.io');
const stripe = require('./lib/stripe');

const authRoutes = require('./routes/auth');
const messageRoutes = require('./routes/messages');
const bankRoutes = require('./routes/bank');
const socialRoutes = require('./routes/social');
const mediaRoutes = require('./routes/media');
const eventRoutes = require('./routes/events');
const paymentRoutes = require('./routes/payments');
// Stripe routes removed - payments not implemented
const stripeRoutes = require('./routes/stripe');
const ticketRoutes = require('./routes/tickets');
const postRoutes = require('./routes/posts');
const followRoutes = require('./routes/follow');
const bookingRoutes = require('./routes/bookings');

const { authenticateSocket } = require('./middleware/socketAuth');
const { initializeSocketHandlers } = require('./socket/handlers');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(morgan('combined'));
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Set socket.io instance for routes that need it
eventRoutes.setSocketIO(io);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/bank', bankRoutes);
app.use('/api/social', socialRoutes);
app.use('/api/media', mediaRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/payments', paymentRoutes);
// Stripe routes removed - payments not implemented
app.use('/api/stripe', stripeRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/posts', postRoutes);
app.use('/api/follow', followRoutes);
app.use('/api/bookings', bookingRoutes);

// Socket.io authentication
io.use(authenticateSocket);

// Socket.io connection handling
io.on('connection', (socket) => {
  console.log(`User ${socket.userId} connected`);
  initializeSocketHandlers(io, socket);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' 
      ? 'Internal server error' 
      : err.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = process.env.PORT || 3000;

httpServer.listen(PORT, () => {
  console.log(`🚀 Sioree backend server running on port ${PORT}`);
  console.log(`📡 Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = { app, io, stripe };


