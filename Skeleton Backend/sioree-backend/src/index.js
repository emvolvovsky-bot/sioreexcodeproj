import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";
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

dotenv.config();

const app = express();

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

// Listen on all interfaces (required for Render)
server.listen(PORT, "0.0.0.0", () => {
  console.log("═══════════════════════════════════════════════════════════");
  console.log(`✅ Sioree Backend Server is RUNNING`);
  console.log(`📡 Port: ${PORT}`);
  console.log(`🌐 API URL: ${API_URL}`);
  console.log(`📊 Database: ${process.env.DATABASE_URL ? "Connected" : "Not connected"}`);
  console.log(`💳 Stripe: ${process.env.STRIPE_SECRET_KEY ? "Configured" : "Not configured"}`);
  console.log(`🔒 Security Headers: Enabled`);
  console.log(`🌍 CORS: ${allowedOrigins.length > 0 ? "Configured" : "Open (development)"}`);
  console.log("═══════════════════════════════════════════════════════════");
});
