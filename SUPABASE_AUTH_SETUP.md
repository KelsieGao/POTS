# Supabase Authentication Setup

## Quick Fix for "localhost refused to connect" Error

### Option 1: Disable Email Confirmation (Recommended for Development)

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** → **Settings**
3. Scroll down to **Email Auth**
4. **Turn OFF** "Enable email confirmations"
5. Save

Now users can sign in immediately after sign up without email verification.

### Option 2: Configure Redirect URLs (For Production)

If you want to keep email verification:

1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL** to your app's URL scheme:
   - For mobile: `pots://auth-callback` or similar
   - For web: `https://yourdomain.com`
3. Add **Redirect URLs**:
   - `pots://auth-callback`
   - `http://localhost:3000` (for development)

## Current Setup

The app now uses:
- ✅ Supabase built-in authentication
- ✅ Email/password signup
- ✅ OTP email verification (6-digit codes)
- ✅ No redirect URLs needed (using OTP)

## Testing

1. **With email confirmation OFF**:
   - Sign up → immediately signed in → goes to home screen

2. **With email confirmation ON**:
   - Sign up → receives 6-digit code via email
   - Enter code → verified → signed in

## Next Steps

After the app is working, you can:
- Re-enable email confirmation for security
- Set up proper redirect URLs for production
- Customize email templates in Authentication → Email Templates

