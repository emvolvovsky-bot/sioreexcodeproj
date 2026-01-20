import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";
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
const HOST = process.env.HOST || "127.0.0.1";
// Default to localhost to avoid EPERM in restricted environments.
// Set HOST=0.0.0.0 explicitly if you need LAN access.
server.listen(PORT, HOST, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🌐 Host: ${HOST}`);
  console.log(`🌐 Accessible at: http://${HOST}:${PORT}`);
});

export { app, server };
