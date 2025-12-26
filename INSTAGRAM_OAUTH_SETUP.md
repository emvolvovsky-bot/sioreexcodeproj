# Instagram OAuth Setup Guide

## Step 1: Create Facebook App and Get Credentials

1. **Go to Facebook Developers**
   - Visit: https://developers.facebook.com/
   - Log in with your Facebook account

2. **Create a New App**
   - Click "My Apps" → "Create App"
   - Choose "Consumer" as the app type
   - Fill in:
     - App Name: `Sioree` (or your preferred name)
     - App Contact Email: Your email
     - Business Account: (Optional)
   - **When asked to "Select Use Cases":**
     - Choose: **"Create app without use case"** or **"Other"**
     - OR if you want to be specific: **"Embed Facebook, Instagram and Threads content in other websites"**
     - You can also select multiple if needed, but "Create app without use case" is the simplest
   - Click "Create App"



4. **Configure Instagram Basic Display**
   - After adding the product, you'll be taken to the Instagram Basic Display settings
   - Facebook may ask about your use case - this is different from the main app use case
   - **For Instagram Basic Display specifically, your use case is:**
     - "Display user's Instagram content on their profile"
     - "Social media account linking and verification"
   - This is just for documentation - the main functionality comes from the scopes you request

5. **Set Up OAuth Redirect URI**
   - Go to "Basic Display" → "Settings"
   - Add OAuth Redirect URIs:
     ```
     sioree://instagram-callback
     ```
   - Click "Add" then "Save Changes"

6. **Get Your Credentials**
   - Go to "Basic Display" → "Basic Display" (or "Settings")
   - You'll see:
     - **App ID** (this is your `INSTAGRAM_CLIENT_ID`)
     - **App Secret** (click "Show" to reveal - this is your `INSTAGRAM_CLIENT_SECRET`)
   - Copy both values

7. **Add Test Users (for development)**
   - Go to "Roles" → "Roles" in the left sidebar
   - Click "Add People" to add yourself as an admin
   - Go to "Instagram Testers" → "Add Instagram Testers"
   - Add your Instagram account as a tester
   - The Instagram account needs to accept the invitation

## Use Cases Explanation

**Why these use cases?**
- **Display user's Instagram content**: Allows your app to show the user's Instagram profile link and basic info on their Sioree profile
- **Social media verification**: Lets users verify their identity by connecting their Instagram account
- **Profile linking**: Enables users to link their Instagram account to their Sioree profile so others can find them

**What your app does:**
- Users connect their Instagram account in Settings → Connect Social Media
- The connected Instagram account appears under their bio on their profile
- Other users can click the link to visit their Instagram profile
- This helps talent showcase their social media presence

## Step 2: Add Environment Variables to Backend

Add these to your `.env` file in `Skeleton Backend/sioree-backend/`:

```bash
INSTAGRAM_CLIENT_ID=your_app_id_here
INSTAGRAM_CLIENT_SECRET=your_app_secret_here
INSTAGRAM_REDIRECT_URI=sioree://instagram-callback
```

### For Render Deployment:

1. Go to your Render dashboard
2. Select your backend service
3. Go to "Environment" tab
4. Add these environment variables:
   - `INSTAGRAM_CLIENT_ID` = (your App ID from step 5)
   - `INSTAGRAM_CLIENT_SECRET` = (your App Secret from step 5)
   - `INSTAGRAM_REDIRECT_URI` = `sioree://instagram-callback`

## Step 3: Test the Integration

1. Restart your backend server (if running locally)
2. In the iOS app, go to Settings → Connect Social Media
3. Click "Connect" next to Instagram
4. You should see Instagram's login page
5. After authorizing, it should connect successfully

## Important Notes:

- **Development Mode**: Your app starts in "Development Mode". Only test users you add can use Instagram login.
- **App Review**: To make it available to all users, you'll need to submit your app for review by Facebook with a clear explanation of how you're using Instagram data.
- **Use Cases**: Make sure you select the correct use cases (see Step 4 above). Facebook may reject apps that don't match their stated use cases.
- **Redirect URI**: Must match exactly: `sioree://instagram-callback` (case-sensitive)
- **Security**: Never commit your App Secret to version control. Always use environment variables.
- **Not for Authentication**: Instagram Basic Display is NOT for user login/authentication. It's for displaying user's Instagram content and linking profiles.

## Troubleshooting:

- **"Invalid redirect URI"**: Make sure the redirect URI in Facebook matches exactly: `sioree://instagram-callback`
- **"User not authorized"**: Make sure you've added your Instagram account as a test user
- **"App not in development mode"**: Check your app status in Facebook Developers dashboard

## Quick Reference:

After setup, your `.env` file should have:
```bash
INSTAGRAM_CLIENT_ID=1234567890123456
INSTAGRAM_CLIENT_SECRET=abcdef1234567890abcdef1234567890
INSTAGRAM_REDIRECT_URI=sioree://instagram-callback
```

Replace the values above with your actual credentials from Facebook Developers.

