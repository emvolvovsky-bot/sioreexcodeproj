
import express from "express";
import { db } from "../db/database.js";
import { getUserIdFromToken } from "../middleware/auth.js";
import stripe from "../lib/stripe.js";

const router = express.Router();

const requireUser = (req, res) => {
  const userId = getUserIdFromToken(req);
  if (!userId) {
    res.status(401).json({ error: "Missing or invalid token" });
    return null;
  }
  return userId;
};

const mapAccount = row => ({
  id: String(row.id),
  bankName: row.institution_name || "Bank Account",
  accountType: row.account_type || "checking",
  last4: row.last4 || "0000",
  isVerified: Boolean(row.stripe_external_account_id || row.plaid_access_token),
  createdAt: row.created_at || new Date().toISOString()
});

const resolveStripeClient = (req) => {
  const mode = req.body?.mode || req.query?.mode || req.headers["x-stripe-mode"];
  if (typeof stripe.getStripeClient === "function") {
    return stripe.getStripeClient(mode);
  }
  return stripe;
};

const ensureStripeAccount = async ({ userId, email, stripeClient, req }) => {
  const existing = await db.query(
    "SELECT stripe_account_id FROM users WHERE id = $1",
    [userId]
  );
  const currentId = existing.rows[0]?.stripe_account_id;
  if (currentId) return currentId;

  const account = await stripeClient.accounts.create({
    type: "custom",
    country: "US",
    email,
    business_type: "individual",
    capabilities: { transfers: { requested: true } }
  });

  await db.query("UPDATE users SET stripe_account_id = $1 WHERE id = $2", [
    account.id,
    userId
  ]);

  return account.id;
};

const resolveConnectUrls = () => {
  const returnUrl =
    process.env.STRIPE_CONNECT_RETURN_URL ||
    process.env.STRIPE_ONBOARDING_RETURN_URL;
  const refreshUrl =
    process.env.STRIPE_CONNECT_REFRESH_URL ||
    process.env.STRIPE_ONBOARDING_REFRESH_URL ||
    returnUrl;

  if (!returnUrl || !refreshUrl) {
    return null;
  }
  return { returnUrl, refreshUrl };
};

// POST /api/bank/link-token - return a mock Plaid link token
router.post("/link-token", async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;

  res.json({
    linkToken: "mock-link-token"
  });
});

// POST /api/bank/onboarding-link - create Stripe Connect onboarding link
router.post("/onboarding-link", async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;

  const stripeClient = resolveStripeClient(req);
  if (!stripeClient || !stripeClient.accountLinks || !stripeClient.accounts) {
    return res.status(500).json({ error: "Stripe is not configured" });
  }

  const connectUrls = resolveConnectUrls();
  if (!connectUrls) {
    return res.status(500).json({
      error: "Stripe Connect URLs are not configured"
    });
  }

  try {
    const userResult = await db.query(
      "SELECT email FROM users WHERE id = $1",
      [userId]
    );
    const email = userResult.rows[0]?.email;
    if (!email) {
      return res.status(400).json({ error: "User email not found" });
    }

    const stripeAccountId = await ensureStripeAccount({
      userId,
      email,
      stripeClient,
      req
    });

    const accountLink = await stripeClient.accountLinks.create({
      account: stripeAccountId,
      refresh_url: connectUrls.refreshUrl,
      return_url: connectUrls.returnUrl,
      type: "account_onboarding"
    });

    return res.json({ url: accountLink.url });
  } catch (error) {
    console.error("Stripe onboarding link error:", error);
    const stripeMessage =
      error?.raw?.message ||
      error?.message ||
      "Failed to create onboarding link";
    return res.status(500).json({ error: stripeMessage });
  }
});

// POST /api/bank/manual - create a bank account via routing/account numbers
router.post("/manual", async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;

  const stripeClient = resolveStripeClient(req);
  if (!stripeClient || !stripeClient.tokens || !stripeClient.accounts) {
    return res.status(500).json({ error: "Stripe is not configured" });
  }

  const {
    bankName,
    accountHolderName,
    accountHolderType = "individual",
    routingNumber,
    accountNumber,
    accountType = "checking"
  } = req.body || {};

  if (!accountHolderName || !routingNumber || !accountNumber) {
    return res.status(400).json({
      error: "accountHolderName, routingNumber, and accountNumber are required"
    });
  }

  const routingTrimmed = String(routingNumber).replace(/\D/g, "");
  const accountTrimmed = String(accountNumber).replace(/\D/g, "");
  if (routingTrimmed.length !== 9) {
    return res.status(400).json({ error: "Routing number must be 9 digits" });
  }
  if (accountTrimmed.length < 4) {
    return res.status(400).json({ error: "Account number is too short" });
  }

  try {
    const userResult = await db.query(
      "SELECT email FROM users WHERE id = $1",
      [userId]
    );
    const email = userResult.rows[0]?.email;
    if (!email) {
      return res.status(400).json({ error: "User email not found" });
    }

    const stripeAccountId = await ensureStripeAccount({
      userId,
      email,
      stripeClient,
      req
    });

    const normalizedAccountType =
      accountType === "savings" ? "savings" : "checking";

    const token = await stripeClient.tokens.create({
      bank_account: {
        country: "US",
        currency: "usd",
        routing_number: routingTrimmed,
        account_number: accountTrimmed,
        account_holder_name: accountHolderName,
        account_holder_type: accountHolderType
      }
    });

    const externalAccount = await stripeClient.accounts.createExternalAccount(
      stripeAccountId,
      {
        external_account: token.id,
        default_for_currency: true
      }
    );

    const last4 = externalAccount?.last4 || accountTrimmed.slice(-4);
    const institution =
      externalAccount?.bank_name || bankName || "Bank Account";

    const result = await db.query(
      `INSERT INTO bank_accounts (
         user_id,
         stripe_external_account_id,
         institution_name,
         account_type,
         last4
       )
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, institution_name, account_type, last4, stripe_external_account_id, created_at`,
      [
        userId,
        externalAccount?.id || null,
        institution,
        normalizedAccountType,
        last4
      ]
    );

    const account = mapAccount(result.rows[0]);
    return res.json(account);
  } catch (error) {
    console.error("Bank account create error:", error);
    return res.status(500).json({ error: "Failed to connect bank account" });
  }
});

// POST /api/bank/exchange-token - store a mock linked bank account
router.post("/exchange-token", async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;

  const publicToken = req.body?.public_token;
  if (!publicToken) {
    return res.status(400).json({ error: "public_token is required" });
  }

  try {
    const result = await db.query(
      `INSERT INTO bank_accounts (user_id, plaid_access_token, plaid_item_id, institution_name)
       VALUES ($1, $2, $3, $4)
       RETURNING id, institution_name, account_type, last4, stripe_external_account_id, created_at`,
      [userId, "mock-access-token", "mock-item-id", "Mock Bank"]
    );

    const account = mapAccount(result.rows[0]);
    return res.json(account);
  } catch (error) {
    console.error("Bank account insert error:", error);
    return res.status(500).json({ error: "Database error" });
  }
});

// GET /api/bank/accounts - list connected accounts
router.get("/accounts", async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;

  try {
    const result = await db.query(
      `SELECT id, institution_name, account_type, last4, stripe_external_account_id, created_at
       FROM bank_accounts
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [userId]
    );

    res.json({ accounts: result.rows.map(mapAccount) });
  } catch (error) {
    console.error("Bank accounts fetch error:", error);
    res.status(500).json({ error: "Database error" });
  }
});

// DELETE /api/bank/accounts/:accountId - remove account
router.delete("/accounts/:accountId", async (req, res) => {
  const userId = requireUser(req, res);
  if (!userId) return;

  try {
    const { accountId } = req.params;
    const result = await db.query(
      "DELETE FROM bank_accounts WHERE id = $1 AND user_id = $2",
      [accountId, userId]
    );
    res.json({ success: result.rowCount > 0 });
  } catch (error) {
    console.error("Bank account delete error:", error);
    res.status(500).json({ error: "Database error" });
  }
});

export default router;
