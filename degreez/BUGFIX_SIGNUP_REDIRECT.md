# Bug Fix: Redirect to Signup Page on Reload

## 🐛 Problem
After implementing the AuthWrapper and Firestore persistence, users were being redirected to the signup page every time they reloaded the website, even though they were already signed in and had completed signup.

## 🔍 Root Cause
The issue was in `login_notifier.dart` - there was a **critical mismatch in document ID usage**:

### What Was Wrong:
```dart
// ❌ WRONG: Using idToken to check for existing student
final docSnapshot = await FirebaseFirestore.instance
    .collection('Students')
    .doc(googleAuth.idToken)  // idToken changes every login!
    .get();
```

### Why This Failed:
1. **During signup**: Students are created with document ID = `user.uid` (the permanent Firebase user ID)
2. **During login check**: Code was looking for document ID = `googleAuth.idToken` (which is a JWT token that changes every time!)
3. **Result**: The check ALWAYS returned "student not found" because it was looking in the wrong place
4. **Outcome**: User was redirected to signup page even though they had already signed up

### The Fix:
```dart
// ✅ CORRECT: Sign in FIRST, then use user.uid to check
final UserCredential userCredential = await _auth!.signInWithCredential(credential);
_user = userCredential.user;

// Now check using the correct, permanent user ID
final docSnapshot = await FirebaseFirestore.instance
    .collection('Students')
    .doc(_user!.uid)  // Use permanent user.uid
    .get();
```

## 🔧 Changes Made

### File: `lib/providers/login_notifier.dart`

**Before:**
1. Created OAuth credential
2. Checked for existing student using `idToken` ❌
3. Signed in to Firebase
4. Set user

**After:**
1. Created OAuth credential
2. Signed in to Firebase **FIRST**
3. Set user
4. Checked for existing student using `user.uid` ✅

### Additional Improvements:
- Added debug logging to `auth_wrapper.dart` to track navigation flow
- Added debug logging to `student_provider.dart` to see cache vs server source
- Better error messages for debugging

## ✅ Result

Now the flow works correctly:
1. User signs in with Google
2. System correctly checks if student profile exists using `user.uid`
3. **Existing users**: Navigate to home page ✅
4. **New users**: Navigate to signup page ✅
5. **On reload**: Users stay on home page (no redirect to signup) ✅

## 🧪 Testing

### Before Fix:
- ❌ Sign in → Complete signup → Reload page → Redirected to signup again

### After Fix:
- ✅ Sign in → Complete signup → Reload page → Stay on home page
- ✅ Cache works correctly
- ✅ Offline mode works correctly

## 📝 Key Takeaway

**Always use `user.uid` for Firestore document IDs**, never use temporary tokens like `idToken`:

- ✅ `user.uid` - Permanent, never changes
- ❌ `idToken` - Temporary JWT, changes every authentication session
- ❌ `accessToken` - Temporary, expires after an hour

## 🎯 Impact

This was a critical bug that would have:
- Made the app unusable for returning users
- Caused data duplication (multiple signup attempts)
- Made caching completely ineffective
- Created a terrible user experience

Now fixed! ✨
