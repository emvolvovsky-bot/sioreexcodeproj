import express from "express";
import { getUserIdFromToken, setFollowState, getFollowingUsers } from "../utils/followHelpers.js";

const router = express.Router();

router.post("/follow/:id", async (req, res) => {
  try {
    const followerId = getUserIdFromToken(req);
    if (!followerId) return res.status(401).json({ error: "Unauthorized" });

    const followingId = req.params.id;
    const result = await setFollowState({ followerId, followingId, shouldFollow: true });

    res.json(result);
  } catch (err) {
    const message = err.message || "Failed to follow user";
    const status = message === "Cannot follow yourself" ? 400 : message === "Unauthorized" ? 401 : 500;
    console.error("Follow error:", err);
    res.status(status).json({ error: message });
  }
});

router.delete("/follow/:id", async (req, res) => {
  try {
    const followerId = getUserIdFromToken(req);
    if (!followerId) return res.status(401).json({ error: "Unauthorized" });

    const followingId = req.params.id;
    const result = await setFollowState({ followerId, followingId, shouldFollow: false });

    res.json(result);
  } catch (err) {
    const message = err.message || "Failed to unfollow user";
    const status = message === "Cannot follow yourself" ? 400 : message === "Unauthorized" ? 401 : 500;
    console.error("Unfollow error:", err);
    res.status(status).json({ error: message });
  }
});

router.get("/following", async (req, res) => {
  try {
    const followerId = getUserIdFromToken(req);
    if (!followerId) return res.status(401).json({ error: "Unauthorized" });

    const users = await getFollowingUsers(followerId);
    const followingIds = users.map(user => user.id);

    res.json({ users, followingIds });
  } catch (err) {
    console.error("Get following error:", err);
    res.status(500).json({ error: "Failed to fetch following list" });
  }
});

export default router;
