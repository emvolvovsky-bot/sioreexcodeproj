import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import http from "http";
import { Server } from "socket.io";

import db from "./db/database.js"; // <-- SQLite database

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// ROUTES
import authRoutes from "./routes/auth.js";
import eventRoutes from "./routes/events.js";
import messageRoutes from "./routes/messages.js";

app.use("/auth", authRoutes);
app.use("/events", eventRoutes);
app.use("/messages", messageRoutes);

// HEALTH CHECK
app.get("/health", (req, res) => {
  res.json({ status: "Backend running", database: "SQLite" });
});

// SOCKET.IO SETUP
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" }
});

io.on("connection", (socket) => {
  console.log("Client connected:", socket.id);

  socket.on("send_message", (payload) => {
    socket.broadcast.emit("receive_message", payload);
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected");
  });
});

// START SERVER
const PORT = process.env.PORT || 4000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
