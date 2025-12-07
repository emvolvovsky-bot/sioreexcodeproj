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
app.use(cors());
app.use(express.json());

// Make io available to routes
app.set("io", io);

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

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

io.on("connection", socket => {
  console.log("Client connected:", socket.id);
  
  // Join conversation room
  socket.on("join_conversation", (conversationId) => {
    socket.join(`conversation:${conversationId}`);
    console.log(`Client ${socket.id} joined conversation ${conversationId}`);
  });
  
  // Leave conversation room
  socket.on("leave_conversation", (conversationId) => {
    socket.leave(`conversation:${conversationId}`);
    console.log(`Client ${socket.id} left conversation ${conversationId}`);
  });
  
  // Handle incoming messages (for real-time sync)
  socket.on("send_message", payload => {
    socket.broadcast.emit("receive_message", payload);
    // Also emit to conversation room
    if (payload.conversationId) {
      io.to(`conversation:${payload.conversationId}`).emit("new_message", payload);
    }
  });
  
  socket.on("disconnect", () => console.log("Client disconnected:", socket.id));
});

const PORT = process.env.PORT || 4000;
// Listen on all interfaces (0.0.0.0) so phone can connect via IP address
server.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🌐 Accessible at: http://localhost:${PORT} or http://192.168.1.200:${PORT}`);
});
