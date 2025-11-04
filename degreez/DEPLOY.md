# Firebase Hosting Deployment Guide

## Quick Deploy (Manual - Requires Firebase CLI)

### Prerequisites
1. Install Node.js from https://nodejs.org/
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Login to Firebase: `firebase login`

### Deploy Steps
```bash
cd "c:\Users\RAMZE\android projects\2025b-DegreEZ\degreez"
flutter build web --release
firebase deploy --only hosting
```

---

## Automated Deployment via GitHub Actions (Recommended)

### One-Time Setup

1. **Get Firebase CI Token** (run this locally after installing Node.js + Firebase CLI):
   ```bash
   firebase login:ci
   ```
   This will open a browser, login with your Google account, and return a token.

2. **Add Token to GitHub Secrets**:
   - Go to: https://github.com/Technion236272/2025b-DegreEZ/settings/secrets/actions
   - Click "New repository secret"
   - Name: `FIREBASE_TOKEN`
   - Value: (paste the token from step 1)
   - Click "Add secret"

3. **Push to `web-version` branch**:
   ```bash
   git add .
   git commit -m "Add web deployment configuration"
   git push origin web-version
   ```

### How It Works
- GitHub Actions will automatically:
  - Build the Flutter web app
  - Deploy to Firebase Hosting
  - Every time you push to the `web-version` branch

### View Your Deployed Site
After deployment completes (check Actions tab on GitHub):
- **Live URL**: https://degreez-fbec6.web.app
- **Or**: https://degreez-fbec6.firebaseapp.com

---

## Manual Local Deploy (If you prefer not to use CI)

### Install Node.js
1. Download from: https://nodejs.org/ (choose LTS version)
2. Run installer
3. Restart PowerShell

### Install Firebase CLI
```powershell
npm install -g firebase-tools
```

### Login and Initialize
```powershell
cd "c:\Users\RAMZE\android projects\2025b-DegreEZ\degreez"
firebase login
firebase use degreez-fbec6
```

### Deploy
```powershell
flutter build web --release
firebase deploy --only hosting
```

Your site will be live at: https://degreez-fbec6.web.app

---

## Troubleshooting

### Build Issues
- Make sure `.env` file exists with Firebase web config
- Run `flutter clean` then `flutter build web --release`

### Deploy Issues
- Verify you're logged in: `firebase login:list`
- Check project: `firebase use`
- Ensure `firebase.json` exists in project root

### GitHub Actions Issues
- Check Actions tab: https://github.com/Technion236272/2025b-DegreEZ/actions
- Verify `FIREBASE_TOKEN` secret is set correctly
- Check workflow file: `.github/workflows/firebase-hosting-deploy.yml`
