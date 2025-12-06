import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import db from "../db/database.js";

const router = express.Router();

/*
---------------------------------------
  HELPER: GENERATE TOKENS
---------------------------------------
*/
function generateTokens(userId) {
  const accessToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "15m" }
  );

  const refreshToken = jwt.sign(
    { userId },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "7d" }
  );

  // Save refresh token in SQLite
  db.prepare(`
    INSERT INTO refresh_tokens (user_id, token)
    VALUES (?, ?)
  `).run(userId, refreshToken);

  return { accessToken, refreshToken };
}

/*
---------------------------------------
  SIGNUP
---------------------------------------
*/
router.post("/signup", (req, res) => {
  const { email, password, name } = req.body;

  if (!email || !password)
    return res.status(400).json({ error: "Email and password required" });

  const exists = db.prepare(`SELECT * FROM users WHERE email = ?`).get(email);
  if (exists)
    return res.status(400).json({ error: "User already exists" });

  const hashed = bcrypt.hashSync(password, 10);

  const result = db.prepare(`
    INSERT INTO users (email, password, name)
    VALUES (?, ?, ?)
  `).run(email, hashed, name || null);

  const userId = result.lastInsertRowid;

  const tokens = generateTokens(userId);

  res.json({
    message: "User created",
    user: { id: userId, email, name },
    ...tokens
  });
});

/*
---------------------------------------
  LOGIN
---------------------------------------
*/
router.post("/login", (req, res) => {
  const { email, password } = req.body;

  const user = db.prepare(`SELECT * FROM users WHERE email = ?`).get(email);
  if (!user)
    return res.status(400).json({ error: "Invalid email or password" });

  const valid = bcrypt.compareSync(password, user.password);
  if (!valid)
    return res.status(400).json({ error: "Invalid email or password" });

  const tokens = generateTokens(user.id);

  res.json({
    message: "Logged in",
    user: { id: user.id, email: user.email, name: user.name },
    ...tokens
  });
});

/*
---------------------------------------
  REFRESH TOKEN
---------------------------------------
*/
router.post("/refresh", (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken)
    return res.status(400).json({ error: "Missing refresh token" });

  const stored = db.prepare(`
    SELECT * FROM refresh_tokens WHERE token = ?
  `).get(refreshToken);

  if (!stored)
    return res.status(401).json({ error: "Invalid refresh token" });

  try {
    const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const tokens = generateTokens(payload.userId);
    res.json(tokens);
  } catch (err) {
    res.status(401).json({ error: "Expired or invalid refresh token" });
  }
});

/*
---------------------------------------
  LOGOUT
---------------------------------------
*/
router.post("/logout", (req, res) => {
  const { refreshToken } = req.body;

  if (refreshToken) {
    db.prepare(`DELETE FROM refresh_tokens WHERE token = ?`).run(refreshToken);
  }

  res.json({ message: "Logged out" });
});

export default router;
