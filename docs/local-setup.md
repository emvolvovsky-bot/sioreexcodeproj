# Local Development Setup

## Testing Events Without Stripe

For local development and testing, you can create ticketed events without setting up Stripe by using the `ALLOW_LOCAL_TICKETS` environment variable.

### Environment Variables

Set any of the following environment variables to `true` to bypass Stripe requirements for ticketed events:

- `ALLOW_LOCAL_TICKETS=true` - Explicitly allow local tickets
- `NODE_ENV=development` - Standard Node.js development mode
- `RUN_LOCAL=true` - Used by the iOS app to connect to localhost

### Example

```bash
# Start the backend with local ticket creation enabled
ALLOW_LOCAL_TICKETS=true npm run dev:legacy

# Or set NODE_ENV
NODE_ENV=development npm run dev:legacy

# Or use RUN_LOCAL (matches iOS app configuration)
RUN_LOCAL=true npm run dev:legacy
```

### What This Does

When enabled, hosts can create events with ticket prices without:
- Having a Stripe Connect account
- Completing Stripe onboarding
- Having valid Stripe credentials

**⚠️ Warning:** This should only be used for local development and testing. In production, Stripe integration is required for ticketed events to handle payments securely.