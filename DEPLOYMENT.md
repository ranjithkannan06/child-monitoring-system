# Vercel Deployment Guide

This guide will help you deploy your Flutter web app to Vercel.

## Prerequisites

1. **Vercel Account**: Sign up at [vercel.com](https://vercel.com)
2. **GitHub Account**: Your code should be in a GitHub repository
3. **Flutter SDK**: Installed on your local machine

## Deployment Steps

### Method 1: Deploy via Vercel Dashboard (Recommended)

1. **Push your code to GitHub**:

   ```bash
   git add .
   git commit -m "Prepare for Vercel deployment"
   git push origin main
   ```

2. **Connect to Vercel**:

   - Go to [vercel.com](https://vercel.com)
   - Click "New Project"
   - Import your GitHub repository
   - Select your repository

3. **Configure Build Settings**:

   - **Framework Preset**: Other
   - **Build Command**: `flutter build web --release`
   - **Output Directory**: `build/web`
   - **Install Command**: `flutter pub get`

4. **Environment Variables** (if needed):

   - Add your Firebase configuration
   - Add any other environment variables

5. **Deploy**:
   - Click "Deploy"
   - Wait for the build to complete
   - Your app will be available at `https://your-project-name.vercel.app`

### Method 2: Deploy via Vercel CLI

1. **Install Vercel CLI**:

   ```bash
   npm install -g vercel
   ```

2. **Login to Vercel**:

   ```bash
   vercel login
   ```

3. **Build your Flutter app**:

   ```bash
   flutter build web --release
   ```

4. **Deploy**:
   ```bash
   vercel --prod
   ```

## Configuration Files

The following files are already configured for Vercel deployment:

- `vercel.json` - Vercel configuration
- `.vercelignore` - Files to ignore during deployment
- `package.json` - Build scripts
- `build_vercel.sh` - Build script (Linux/Mac)

## Environment Variables

Make sure to set these environment variables in Vercel:

- `FIREBASE_API_KEY`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_APP_ID`
- `FIREBASE_MEASUREMENT_ID`
- `FIREBASE_DATABASE_URL`
- `GOOGLE_SIGN_IN_CLIENT_ID`

## Troubleshooting

### Build Fails

- Check that Flutter SDK is available in the build environment
- Ensure all dependencies are properly listed in `pubspec.yaml`
- Check the build logs in Vercel dashboard

### App Doesn't Load

- Verify the output directory is set to `build/web`
- Check that all static assets are properly included
- Ensure Firebase configuration is correct

### Firebase Issues

- Make sure your Firebase project allows your Vercel domain
- Check that all environment variables are set correctly
- Verify Firebase security rules

## Custom Domain

To use a custom domain:

1. Go to your project in Vercel dashboard
2. Click "Settings" → "Domains"
3. Add your custom domain
4. Update DNS records as instructed

## Performance Optimization

- The app is built with `--web-renderer html` for better compatibility
- Static assets are optimized for production
- Firebase is configured for web deployment

## Support

If you encounter issues:

1. Check Vercel build logs
2. Verify Flutter web compatibility
3. Test locally with `flutter run -d chrome`
