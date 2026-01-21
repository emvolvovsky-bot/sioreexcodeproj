const Stripe = require('stripe');

const normalizeMode = (mode) => {
  if (!mode) return undefined;
  const normalized = String(mode).trim().toLowerCase();
  if (normalized === 'test' || normalized === 'live') {
    return normalized;
  }
  return undefined;
};

const resolveSecretKey = (mode) => {
  const normalized = normalizeMode(mode);
  if (normalized === 'test') {
    return process.env.STRIPE_TEST_SECRET_KEY || process.env.STRIPE_SECRET_KEY;
  }
  if (normalized === 'live') {
    return process.env.STRIPE_SECRET_KEY || process.env.STRIPE_LIVE_SECRET_KEY;
  }
  return (
    process.env.STRIPE_TEST_SECRET_KEY ||
    process.env.STRIPE_SECRET_KEY ||
    process.env.STRIPE_LIVE_SECRET_KEY
  );
};

const resolvePublishableKey = (mode) => {
  const normalized = normalizeMode(mode);
  if (normalized === 'test') {
    return process.env.STRIPE_TEST_PUBLISHABLE_KEY || process.env.STRIPE_PUBLISHABLE_KEY;
  }
  if (normalized === 'live') {
    return process.env.STRIPE_PUBLISHABLE_KEY || process.env.STRIPE_LIVE_PUBLISHABLE_KEY;
  }
  return (
    process.env.STRIPE_TEST_PUBLISHABLE_KEY ||
    process.env.STRIPE_PUBLISHABLE_KEY ||
    process.env.STRIPE_LIVE_PUBLISHABLE_KEY
  );
};

const clients = new Map();

const getStripeClient = (mode) => {
  const normalized = normalizeMode(mode);
  const cacheKey = normalized || 'default';
  if (clients.has(cacheKey)) {
    return clients.get(cacheKey);
  }
  const secretKey = resolveSecretKey(normalized);
  if (!secretKey) {
    return null;
  }
  const client = Stripe(secretKey);
  clients.set(cacheKey, client);
  return client;
};

const defaultClient = getStripeClient(process.env.STRIPE_MODE);

if (!defaultClient) {
  module.exports = Stripe('');
} else {
  defaultClient.getStripeClient = getStripeClient;
  defaultClient.getPublishableKey = resolvePublishableKey;
  defaultClient.getStripeMode = normalizeMode;
  module.exports = defaultClient;
}

