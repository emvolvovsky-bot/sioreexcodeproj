import express from "express";

const router = express.Router();

// All payment endpoints return placeholder responses
router.post("/create-intent", (req, res) => {
  console.log("💳 Payments create-intent:", req.body);
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.get("/methods", (req, res) => {
  console.log("💳 Payments methods:", req.query);
  res.json({ paymentMethods: [] });
});

router.post("/save-method", (req, res) => {
  console.log("💳 Payments save-method:", req.body);
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.delete("/methods/:id", (req, res) => {
  console.log("💳 Payments delete-method:", req.params);
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.post("/set-default", (req, res) => {
  console.log("💳 Payments set-default:", req.body);
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.post("/create-method", (req, res) => {
  console.log("💳 Payments create-method:", req.body);
  res.status(501).json({ error: "Payment processing is not implemented" });
});

router.post("/confirm", (req, res) => {
  console.log("💳 Payments confirm:", req.body);
  res.status(501).json({ error: "Payment processing is not implemented" });
});

export default router;
