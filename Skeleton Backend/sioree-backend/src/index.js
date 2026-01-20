import express from "express";
import cors from "cors";
import dotenv from "dotenv"
dotenv.config();
;
import http from "http";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { Server } from "socket.io";
import db from "./db/database.js";
import authRoutes from "./routes/auth.js";
import eventRoutes from "./routes/events.js";
import messageRoutes from "./routes/messages.js";
import paymentRoutes from "./routes/payments.js";
import userRoutes from "./routes/users.js";
import feedRoutes from "./routes/feed.js";
import searchRoutes from "./routes/search.js";
import postRoutes from "./routes/posts.js";
import talentRoutes from "./routes/talent.js";
import notificationRoutes from "./routes/notifications.js";
import bookingRoutes from "./routes/bookings.js";
import reviewRoutes from "./routes/reviews.js";
import socialRoutes from "./routes/social.js";
import brandRoutes from "./routes/brands.js";
import bankRoutes from "./routes/bank.js";
import earningsRoutes from "./routes/earnings.js";
import mediaRoutes from "./routes/media.js";
import stripeRoutes from "./routes/stripe.js";

dotenv.config();

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const migrationsDir = path.join(__dirname, "..", "migrations");

// Run migrations automatically on boot to avoid missing columns in production
async function runMigrationsOnBoot() {
  const migrationFiles = [
    "001_initial_schema.sql",
    "002_add_user_fields.sql",
    "003_add_messaging_tables.sql",
    "004_add_social_features.sql",
    "005_add_event_promotions.sql",
    "006_add_reviews.sql",
    "007_add_event_talent_needs.sql",
    "008_add_role_to_messages.sql",
    "009_add_event_id_to_posts.sql",
    "010_add_group_chats.sql",
    "011_add_event_talent_table.sql",
    "012_add_brand_insights_tables.sql",
    "013_add_user_type_to_follows.sql",
    "014_add_earnings_tables.sql"
  ];

  for (const file of migrationFiles) {
    const filePath = path.join(migrationsDir, file);
    if (!fs.existsSync(filePath)) {
      console.warn(`⚠️ Migration ${file} not found at ${filePath}, skipping`);
      continue;
    }

    try {
      const sql = fs.readFileSync(filePath, "utf8");
      console.log(`🔄 Running migration ${file}...`);
      await db.query(sql);
      console.log(`✅ Migration ${file} applied`);
    } catch (err) {
      // Ignore idempotent errors so boot can continue
      const msg = err.message || "";
      if (
        msg.includes("already exists") ||
        msg.includes("duplicate key") ||
        msg.includes("duplicate column")
      ) {
        console.log(`ℹ️ Migration ${file} already applied (or partially), continuing`);
      } else {
        console.error(`⚠️ Migration ${file} failed:`, msg);
      }
    }
  }

  console.log("✅ Boot migrations completed (non-blocking)");
}

// Minimal schema guard for production where migrations may be stale
async function ensureCoreSchema() {
  try {
    // Messaging columns
    await db.query(`
      ALTER TABLE messages
        ADD COLUMN IF NOT EXISTS sender_role VARCHAR(50),
        ADD COLUMN IF NOT EXISTS receiver_role VARCHAR(50),
        ADD COLUMN IF NOT EXISTS text TEXT,
        ADD COLUMN IF NOT EXISTS message_type VARCHAR(50) DEFAULT 'text',
        ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;
    `);

    // Event promotions + featured flag
    await db.query(`
      CREATE TABLE IF NOT EXISTS event_promotions (
        id SERIAL PRIMARY KEY,
        event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        brand_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        promoted_at TIMESTAMP DEFAULT NOW(),
        expires_at TIMESTAMP,
        is_active BOOLEAN DEFAULT true,
        promotion_budget DECIMAL(10, 2) DEFAULT 0.00,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(event_id, brand_id)
      );
      CREATE INDEX IF NOT EXISTS idx_event_promotions_event_id ON event_promotions(event_id);
      CREATE INDEX IF NOT EXISTS idx_event_promotions_brand_id ON event_promotions(brand_id);
      CREATE INDEX IF NOT EXISTS idx_event_promotions_active ON event_promotions(is_active, expires_at);
      ALTER TABLE events ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false;
    `);

    // Stripe Connect fields (payout readiness)
    await db.query(`
      ALTER TABLE users
        ADD COLUMN IF NOT EXISTS stripe_account_id TEXT;
      ALTER TABLE bank_accounts
        ADD COLUMN IF NOT EXISTS stripe_external_account_id TEXT,
        ADD COLUMN IF NOT EXISTS account_type VARCHAR(20),
        ADD COLUMN IF NOT EXISTS last4 VARCHAR(4);
      ALTER TABLE withdrawals
        ADD COLUMN IF NOT EXISTS stripe_payout_id TEXT;
    `);

    console.log("✅ Core schema guard executed");
  } catch (err) {
    console.error("⚠️ Core schema guard failed (non-blocking):", err.message);
  }
}

// Run migrations then ensure critical columns/tables exist (non-blocking if fails)
(async () => {
  try {
    await runMigrationsOnBoot();
    await ensureCoreSchema();
  } catch (err) {
    console.error("⚠️ Startup schema guard failed (continuing):", err.message);
  }
})();

// Security Headers Middleware
app.use((req, res, next) => {
  // Prevent XSS attacks
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("X-XSS-Protection", "1; mode=block");
  
  // Prevent MIME type sniffing
  res.setHeader("Content-Security-Policy", "default-src 'self'");
  
  // Strict Transport Security (HSTS) - only in production
  if (process.env.NODE_ENV === "production") {
    res.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
  }
  
  // Referrer Policy
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  
  // Permissions Policy
  res.setHeader("Permissions-Policy", "geolocation=(), microphone=(), camera=()");
  
  // Remove server information
  res.removeHeader("X-Powered-By");
  
  next();
});

// CORS Configuration - Restrict to specific origins
const allowedOrigins = [
  "https://sioree-api.onrender.com",
  process.env.FRONTEND_URL,
  process.env.ALLOWED_ORIGIN
].filter(Boolean); // Remove undefined values

// Add development origins only in development mode
if (process.env.NODE_ENV === "development") {
  allowedOrigins.push("http://localhost:3000");
}

const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) {
      return callback(null, true);
    }
    
    if (allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error("Not allowed by CORS"));
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
  exposedHeaders: ["X-Total-Count"],
  maxAge: 86400 // 24 hours
};

app.use(cors(corsOptions));
app.use(express.json({ limit: "10mb" })); // Limit request body size

// Media ping for connectivity checks (place before other routes)
app.get("/api/media/ping", (req, res) => {
  console.log("PING /api/media/ping");
  res.json({ ok: true, source: "Skeleton Backend/sioree-backend/src/index.js" });
});
// Handle possible trailing slash or double slashes
app.get(/^\/api\/media\/ping\/?$/, (req, res) => {
  console.log("PING /api/media/ping (regex)");
  res.json({ ok: true, source: "Skeleton Backend/sioree-backend/src/index.js" });
});

// Request logging middleware (sanitized - no IPs or sensitive data)
// Place BEFORE routes to log all requests
app.use((req, res, next) => {
  // Log requests without exposing sensitive information
  // Sanitize URLs to hide IDs and sensitive paths
  let sanitizedUrl = req.url;
  // Hide user IDs, event IDs, etc. in URLs
  sanitizedUrl = sanitizedUrl.replace(/\/api\/[^\/]+\/([^\/\?]+)/g, "/api/*/***");
  // Don't log query parameters as they may contain sensitive data
  if (sanitizedUrl.includes("?")) {
    sanitizedUrl = sanitizedUrl.split("?")[0] + "?***";
  }
  console.log(`📥 ${req.method} ${sanitizedUrl}`);
  next();
});

const server = http.createServer(app);

// Socket.io CORS configuration - match Express CORS
const io = new Server(server, { 
  cors: {
    origin: function(origin, callback) {
      // Allow requests with no origin (mobile apps)
      if (!origin) {
        return callback(null, true);
      }
      if (allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error("Not allowed by CORS"));
      }
    },
    methods: ["GET", "POST"],
    credentials: true
  }
});

// Make io available to routes
app.set("io", io);

// Log startup
console.log("🚀 Starting Sioree Backend Server...");
console.log("📦 Environment:", process.env.NODE_ENV || "development");
console.log("🔗 Database:", process.env.DATABASE_URL ? "Configured" : "Not configured");
console.log("💳 Stripe:", process.env.STRIPE_SECRET_KEY ? "Configured" : "Not configured");

app.use("/api/auth", authRoutes);
app.use("/api/events", eventRoutes);
app.use("/api/messages", messageRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/users", userRoutes);
app.use("/api/feed", feedRoutes);
app.use("/api/search", searchRoutes);
app.use("/api/posts", postRoutes);
app.use("/api/talent", talentRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/reviews", reviewRoutes);
app.use("/api/brands", brandRoutes);
app.use("/api/social", socialRoutes);
app.use("/api/bank", bankRoutes);
app.use("/api/earnings", earningsRoutes);
app.use("/api/media", mediaRoutes);
app.use("/api/stripe", stripeRoutes);

app.get("/health", (req, res) => {
  res.json({ status: "Backend running", database: "Supabase Postgres" });
});

app.get("/api/health", (req, res) => {
  res.json({ status: "Backend running", database: "Supabase Postgres" });
});

io.on("connection", socket => {
  // Don't log socket IDs as they could be used to track users
  console.log("🔌 Client connected");
  
  // Join conversation room
  socket.on("join_conversation", (conversationId) => {
    socket.join(`conversation:${conversationId}`);
    // Don't log conversation IDs
  });
  
  // Leave conversation room
  socket.on("leave_conversation", (conversationId) => {
    socket.leave(`conversation:${conversationId}`);
  });
  
  // Handle incoming messages (for real-time sync)
  socket.on("send_message", payload => {
    socket.broadcast.emit("receive_message", payload);
    // Also emit to conversation room
    if (payload.conversationId) {
      io.to(`conversation:${payload.conversationId}`).emit("new_message", payload);
    }
  });
  
  socket.on("disconnect", () => console.log("🔌 Client disconnected"));
});

const PORT = process.env.PORT || 4000;
const API_URL = process.env.API_URL || `https://sioree-api.onrender.com`;
const HOST =
  process.env.HOST ||
  (process.env.RENDER || process.env.NODE_ENV === "production"
    ? "0.0.0.0"
    : "127.0.0.1");

// Listen on all interfaces for Render, localhost for dev
server.listen(PORT, HOST, () => {
  console.log("═══════════════════════════════════════════════════════════");
  console.log(`✅ Sioree Backend Server is RUNNING`);
  console.log(`📡 Port: ${PORT}`);
  console.log(`🖥️ Host: ${HOST}`);
  console.log(`🌐 API URL: ${API_URL}`);
  console.log(`📊 Database: ${process.env.DATABASE_URL ? "Connected" : "Not connected"}`);
  console.log(`💳 Stripe: ${process.env.STRIPE_SECRET_KEY ? "Configured" : "Not configured"}`);
  console.log(`🔒 Security Headers: Enabled`);
  console.log(`🌍 CORS: ${allowedOrigins.length > 0 ? "Configured" : "Open (development)"}`);
  console.log("═══════════════════════════════════════════════════════════");
});
