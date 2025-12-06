const express = require('express');
const plaid = require('plaid');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');
const { encryptForStorage } = require('../utils/encryption');

const router = express.Router();
router.use(authenticate);

// Initialize Plaid client
const plaidClient = new plaid.Client({
  clientID: process.env.PLAID_CLIENT_ID,
  secret: process.env.PLAID_SECRET,
  env: process.env.PLAID_ENV === 'production' 
    ? plaid.environments.production 
    : plaid.environments.sandbox,
});

// POST /api/bank/link-token
router.post('/link-token', async (req, res) => {
  try {
    const response = await plaidClient.createLinkToken({
      user: {
        client_user_id: req.user.id,
      },
      client_name: 'Sioree',
      products: ['auth', 'transactions'],
      country_codes: ['US'],
      language: 'en',
    });
    
    res.json({ 
      linkToken: response.link_token,
      expiration: new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString(), // 4 hours
    });
  } catch (error) {
    console.error('Plaid link token error:', error);
    res.status(500).json({ error: 'Failed to create link token' });
  }
});

// POST /api/bank/exchange-token
router.post('/exchange-token', async (req, res) => {
  try {
    const { publicToken } = req.body;
    
    if (!publicToken) {
      return res.status(400).json({ error: 'Public token required' });
    }
    
    // Exchange public token for access token
    const response = await plaidClient.exchangePublicToken(publicToken);
    const accessToken = response.access_token;
    const itemId = response.item_id;
    
    // Get account information
    const accountsResponse = await plaidClient.getAccounts(accessToken);
    const account = accountsResponse.accounts[0];
    
    if (!account) {
      return res.status(400).json({ error: 'No account found' });
    }
    
    // Encrypt access token
    const encryptedToken = encryptForStorage(accessToken);
    
    // Save to database
    const result = await query(
      `INSERT INTO bank_accounts 
       (user_id, bank_name, account_type, last4, plaid_access_token_encrypted, plaid_item_id, is_verified, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, true, NOW(), NOW())
       RETURNING id, bank_name, account_type, last4, is_verified, created_at`,
      [
        req.user.id,
        account.name || 'Unknown Bank',
        account.type,
        account.mask || '****',
        encryptedToken,
        itemId,
      ]
    );
    
    const bankAccount = result.rows[0];
    
    res.json({
      account: {
        id: bankAccount.id,
        bankName: bankAccount.bank_name,
        accountType: bankAccount.account_type,
        last4: bankAccount.last4,
        isVerified: bankAccount.is_verified,
        createdAt: bankAccount.created_at,
      },
    });
  } catch (error) {
    console.error('Plaid exchange token error:', error);
    res.status(500).json({ error: 'Failed to exchange token' });
  }
});

// GET /api/bank/accounts
router.get('/accounts', async (req, res) => {
  try {
    const result = await query(
      `SELECT id, bank_name, account_type, last4, is_verified, created_at
       FROM bank_accounts
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.user.id]
    );
    
    const accounts = result.rows.map(row => ({
      id: row.id,
      bankName: row.bank_name,
      accountType: row.account_type,
      last4: row.last4,
      isVerified: row.is_verified,
      createdAt: row.created_at,
    }));
    
    res.json({ accounts });
  } catch (error) {
    console.error('Get bank accounts error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/bank/accounts/:accountId
router.delete('/accounts/:accountId', async (req, res) => {
  try {
    const { accountId } = req.params;
    
    // Verify ownership
    const accountResult = await query(
      'SELECT id, plaid_item_id FROM bank_accounts WHERE id = $1 AND user_id = $2',
      [accountId, req.user.id]
    );
    
    if (accountResult.rows.length === 0) {
      return res.status(404).json({ error: 'Account not found' });
    }
    
    const account = accountResult.rows[0];
    
    // Remove from Plaid (optional - you might want to keep it for history)
    // await plaidClient.removeItem(account.plaid_item_id);
    
    // Delete from database
    await query(
      'DELETE FROM bank_accounts WHERE id = $1',
      [accountId]
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Delete bank account error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;



