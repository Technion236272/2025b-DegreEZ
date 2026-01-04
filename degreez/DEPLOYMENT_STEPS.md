# 🚀 Firebase Hosting Deployment - What You Need to Do

## ✅ What's Already Done
- ✅ Flutter web build completed successfully (`build/web`)
- ✅ Firebase configuration files created (`firebase.json`, `.firebaserc`)
- ✅ GitHub Actions workflow configured (`.github/workflows/firebase-hosting-deploy.yml`)
- ✅ Web app tested and working locally

---

## 🎯 What You Need to Do Now

### **Option A: Automated Deployment via GitHub Actions (Easiest)**

#### Step 1: Install Node.js (one-time setup)
1. Download from: https://nodejs.org/en/download/
2. Choose **Windows Installer (.msi)** - LTS version
3. Run the installer (accept all defaults)
4. **Restart your PowerShell/terminal**

#### Step 2: Install Firebase CLI & Get Token
After Node.js is installed and you've restarted your terminal:
```powershell
npm install -g firebase-tools
firebase login:ci
```
- This will open a browser
- Login with your Google account (same one used for Firebase)
- Copy the token that appears in the terminal

#### Step 3: Add Token to GitHub Secrets
1. Go to: https://github.com/Technion236272/2025b-DegreEZ/settings/secrets/actions
2. Click **"New repository secret"**
3. Name: `FIREBASE_TOKEN`
4. Value: *paste the token from Step 2*
5. Click **"Add secret"**

#### Step 4: Push Your Code
```powershell
cd "c:\Users\RAMZE\android projects\2025b-DegreEZ\degreez"
git add .
git commit -m "Add Firebase Hosting configuration for web deployment"
git push origin develop
```

#### Step 5: Watch the Deployment
- Go to: https://github.com/Technion236272/2025b-DegreEZ/actions
- You'll see the build and deploy running
- Wait ~2-3 minutes for completion
- Your site will be live at: **https://degreez.web.app**

---

### **Option B: Manual Deployment (If you prefer)**

#### Prerequisites (one-time)
1. Install Node.js (see Step 1 above)
2. Install Firebase CLI:
   ```powershell
   npm install -g firebase-tools
   ```
3. Login to Firebase:
   ```powershell
   firebase login
   ```

#### Deploy Commands
```powershell
cd "c:\Users\RAMZE\android projects\2025b-DegreEZ\degreez"
flutter build web --release
firebase deploy --only hosting
```

Your site will be live at: **https://degreez.web.app**

---

## 🌐 Your Live URLs (after deployment)
- **Primary**: https://degreez.web.app
- **Alternate**: https://degreez-fbec6.firebaseapp.com

---

## 📝 Important Notes

### .env File
- The `.env` file with your Firebase keys is currently in your local project
- **DO NOT commit it to GitHub** (it contains secrets)
- For production, you should:
  1. Add `.env` to `.gitignore`
  2. Use FlutterFire CLI to generate proper `firebase_options.dart` OR
  3. Set environment variables in Firebase Hosting config

### Custom Domain (Optional)
Once deployed, you can add a custom domain:
1. Go to Firebase Console → Hosting
2. Click "Add custom domain"
3. Follow the instructions

---

## 🆘 Need Help?

If you run into any issues:
1. Check the detailed guide in `DEPLOY.md`
2. Verify Node.js is installed: `node --version`
3. Verify Firebase CLI is installed: `firebase --version`
4. Check GitHub Actions logs for CI deployment issues

---

## 🎉 Next Steps After Deployment

1. Test your live site at https://degreez.web.app
2. Enable Google Sign-In for your production domain in Firebase Console
3. Add authorized domains for OAuth (if needed)
4. Monitor usage in Firebase Console
