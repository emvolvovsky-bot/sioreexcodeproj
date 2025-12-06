import express from "express";
import db from "../db/database.js";

const router = express.Router();

// 🔹 Create a new event
router.post("/create", (req, res) => {
  const { creatorId, title, description, location, date } = req.body;

  if (!creatorId || !title || !location || !date) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  const stmt = db.prepare(
    "INSERT INTO events (creator_id, title, description, location, date) VALUES (?, ?, ?, ?, ?)"
  );

  stmt.run([creatorId, title, description || "", location, date], function (err) {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ success: true, eventId: this.lastID });
  });
});

// 🔹 List all events
router.get("/", (req, res) => {
  const stmt = db.prepare("SELECT * FROM events ORDER BY date ASC");
  stmt.all([], (err, rows) => {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ events: rows });
  });
});

// 🔹 Join an event
router.post("/attend", (req, res) => {
  const { userId, eventId } = req.body;

  if (!userId || !eventId) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  const stmt = db.prepare(
    "INSERT INTO event_attendees (event_id, user_id) VALUES (?, ?)"
  );

  stmt.run([eventId, userId], function (err) {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ success: true });
  });
});

// 🔹 Get attendees for an event
router.get("/:eventId/attendees", (req, res) => {
  const id = req.params.eventId;

  const stmt = db.prepare(
    "SELECT users.id, users.username FROM event_attendees JOIN users ON users.id = event_attendees.user_id WHERE event_attendees.event_id = ?"
  );

  stmt.all([id], (err, rows) => {
    if (err) {
      return res.status(500).json({ error: "Database error", details: err });
    }
    return res.json({ attendees: rows });
  });
});

export default router;
