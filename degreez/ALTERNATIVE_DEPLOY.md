# Alternative: Get Firebase Token Without Installing Node.js

## Method 1: Use GitHub's Web Interface to Trigger Deployment

You can set up GitHub Actions to deploy automatically without needing a Firebase token locally.

### Steps:

1. **Push your code to GitHub:**
   ```powershell
   cd "c:\Users\RAMZE\android projects\2025b-DegreEZ\degreez"
   git add .
   git commit -m "Add Firebase Hosting configuration"
   git push origin web-version
   ```

2. **GitHub Actions will fail the first time** (expected - no token yet)

3. **Get Firebase Token Using Google Cloud Console:**
   - Go to: https://console.cloud.google.com/apis/credentials?project=degreez-fbec6
   - Click "Create Credentials" → "API Key"
   - Copy the API key

4. **OR Get Firebase CI Token via Python (if you have Python):**
   ```powershell
   python -m webbrowser "https://accounts.google.com/o/oauth2/auth?client_id=563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com&scope=email%20openid%20https://www.googleapis.com/auth/cloudplatformprojects.readonly%20https://www.googleapis.com/auth/firebase%20https://www.googleapis.com/auth/cloud-platform&response_type=code&redirect_uri=urn:ietf:wg:oauth:2.0:oob"
   ```

5. **Add Token to GitHub Secrets:**
   - Go to: https://github.com/Technion236272/2025b-DegreEZ/settings/secrets/actions
   - Click "New repository secret"
   - Name: `FIREBASE_TOKEN`
   - Value: (paste the token)

6. **Re-run the GitHub Action:**
   - Go to: https://github.com/Technion236272/2025b-DegreEZ/actions
   - Click on the failed workflow
   - Click "Re-run all jobs"

---

## Method 2: Manual Deploy (Simplest - No Token Needed)

### Option A: Use Firebase Web Console
1. Go to: https://console.firebase.google.com/project/degreez-fbec6/hosting
2. Click "Get Started"
3. Your `build/web` folder is ready at:
   ```
   c:\Users\RAMZE\android projects\2025b-DegreEZ\degreez\build\web
   ```
4. Zip the contents of `build/web` folder
5. Upload the zip file via Firebase Console

### Option B: Use Flutter Web Preview
1. Flutter has a built-in web server:
   ```powershell
   cd "c:\Users\RAMZE\android projects\2025b-DegreEZ\degreez\build\web"
   python -m http.server 8080
   ```
2. Open: http://localhost:8080

---

## Method 3: Simplest - Let Me Help You Get the Token

I can guide you through getting the Firebase token without installing Node.js:

### Using Windows Package Manager (winget)
If you have Windows 10/11, you can try:
```powershell
winget install OpenJS.NodeJS.LTS
```

Then restart PowerShell and run:
```powershell
npm install -g firebase-tools
firebase login:ci
```

---

## What I Recommend:

**Try Method 2, Option A (Firebase Web Console)** - it's the simplest and requires no installation:

1. Zip your `build/web` folder
2. Upload to Firebase Console
3. Done!

Would you like me to guide you through that?
