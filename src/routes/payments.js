import express from "express";

const router = express.Router();

// All payment endpoints return placeholder responses
router.post("/create-intent", (req, res) => {
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.get("/methods", (req, res) => {
  res.json({ paymentMethods: [] });
});

router.post("/save-method", (req, res) => {
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.delete("/methods/:id", (req, res) => {
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.post("/set-default", (req, res) => {
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.post("/create-method", (req, res) => {
  res.status(501).json({ error: "Payment processing is not implemented" });
});

export default router;

// Placeholder webhook handler
export const paymentsWebhookHandler = async (req, res) => {
  res.status(501).json({ error: "Payment processing is not implemented" });
};
