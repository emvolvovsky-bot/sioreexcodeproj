import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";
import fs from "fs";
import authRoutes from "./routes/auth.js";
import eventRoutes from "./routes/events.js";
import messageRoutes from "./routes/messages.js";
import paymentRoutes, { paymentsWebhookHandler } from "./routes/payments.js";
import userRoutes from "./routes/users.js";
import feedRoutes from "./routes/feed.js";
import searchRoutes from "./routes/search.js";
import postRoutes from "./routes/posts.js";
import talentRoutes from "./routes/talent.js";
import notificationRoutes from "./routes/notifications.js";
import bookingRoutes from "./routes/bookings.js";
import reviewRoutes from "./routes/reviews.js";
import followRoutes from "./routes/follow.js";
import mediaRoutes from "./routes/media.js";
import earningsRoutes from "./routes/earnings.js";
import stripeRoutes from "./routes/stripe.js";
import bankRoutes from "./routes/bank.js";

dotenv.config();

const app = express();
app.use(cors());

// Stripe webhook must use raw body (register before json parser)
app.post("/api/payments/webhook", express.raw({ type: "application/json" }), paymentsWebhookHandler);

// JSON parser for normal routes
app.use(express.json());

// Load master API key from file
let MASTER_API_KEY = "";
try {
  const keyPath = new URL("../Sioree XCode Project/sioree_master_word.txt", import.meta.url);
  MASTER_API_KEY = fs.readFileSync(keyPath, "utf8").trim();
  if (!MASTER_API_KEY) {
    console.warn("Master API key file is empty.");
  }
} catch (err) {
  console.error("Failed to read master API key file:", err.message);
}

// Middleware to require master API key on all requests (except webhook which is registered before)
function requireMasterKey(req, res, next) {
  // Allow key via query param, JSON body, or header (x-master-key)
  const provided =
    (req.query && (req.query.master_key || req.query.masterKey)) ||
    (req.body && (req.body.master_key || req.body.masterKey)) ||
    req.headers["x-master-key"] ||
    req.headers["x_master_key"];

  if (!MASTER_API_KEY) {
    return res.status(500).json({ error: "Server misconfigured: master API key not set" });
  }

  if (!provided || provided !== MASTER_API_KEY) {
    return res.status(401).json({ error: "Invalid or missing API key" });
  }

  return next();
}

// Require master key for all routes registered after this point
app.use(requireMasterKey);

// Simple media ping for connectivity checks
app.get("/api/media/ping", (req, res) => {
  res.json({ ok: true, source: "src/index.js" });
});

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
app.use("/api", followRoutes);
app.use("/api/media", mediaRoutes);
app.use("/api/earnings", earningsRoutes);
app.use("/api/stripe", stripeRoutes);
app.use("/api/bank", bankRoutes);

app.get("/health", (req, res) => {
  res.json({ status: "Backend running", database: "Supabase Postgres" });
});

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

io.on("connection", socket => {
  console.log("Client connected:", socket.id);
  socket.on("send_message", payload => socket.broadcast.emit("receive_message", payload));
  socket.on("disconnect", () => console.log("Client disconnected"));
});

const PORT = process.env.PORT || 4000;
const HOST = process.env.HOST; // if unset, bind to all interfaces (OS default)
// If you need to bind to IPv6/IPv4 specifically, set HOST environment variable
if (HOST) {
  server.listen(PORT, HOST, () => {
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`🌐 Host: ${HOST}`);
    console.log(`🌐 Accessible at: http://${HOST}:${PORT}`);
  });
} else {
  server.listen(PORT, () => {
    console.log(`✅ Server running on port ${PORT}`);
    console.log(`🌐 Host: all interfaces`);
    console.log(`🌐 Accessible at: http://127.0.0.1:${PORT} and http://[::1]:${PORT} (if OS supports IPv6)`);
    console.log('Starting server:', __filename, 'cwd:', process.cwd(), 'dirname:', __dirname);
  });
}

export { app, server };
