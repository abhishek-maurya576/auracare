# Firebase Authentication Troubleshooting Guide

This guide helps resolve common authentication issues in the AuraCare app.

## 🔧 Quick Fixes Applied

### ✅ **Google Sign-In Web Configuration**

**Problem:** `ClientID not set` error for web platform.

**Solution Applied:**
- Added Google Sign-In client ID to `web/index.html`
- Added meta tag: `<meta name="google-signin-client_id" content="650633860695-nbm4gru191dfitck2n5vjflknktqp1b5.apps.googleusercontent.com">`

### ✅ **Enhanced Error Handling**

**Problem:** Generic error messages not helpful for debugging.

**Solution Applied:**
- Added detailed logging to AuthService
- Enhanced Firebase Auth exception handling
- Added specific error messages for common issues

### ✅ **Email Authentication Issues**

**Problem:** "Invalid credential" errors during sign-in.

**Solution Applied:**
- Added email trimming to remove whitespace
- Enhanced error logging
- Added password reset functionality

## 🐛 Common Issues & Solutions

### 1. **Google Sign-In Issues**

#### **Problem:** Google Sign-In fails on web
```
Google Sign-ln failed: Assertion failed: appClientld != null
```

#### **Solution Checklist:**
- ✅ Client ID added to `web/index.html`
- ⚠️ Check Firebase Console Google Auth is enabled
- ⚠️ Verify web app is registered in Firebase Console
- ⚠️ Ensure correct OAuth redirect URIs are configured

#### **Firebase Console Settings to Check:**
1. Go to Firebase Console → Authentication → Sign-in method
2. Enable Google Sign-In provider
3. Add authorized domains (localhost, your domain)
4. Download and verify `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)

### 2. **Email Authentication Issues**

#### **Problem:** "Invalid credential" during email sign-in
```
Authentication error: The supplied auth credential is incorrect, malformed or has expired
```

#### **Solution Checklist:**
- ✅ Email/Password auth enabled in Firebase Console
- ✅ Email trimming implemented
- ⚠️ Check if user exists (create account first)
- ⚠️ Verify password meets minimum requirements (6+ characters)

#### **Debug Steps:**
1. Check Firebase Console logs
2. Look at browser console for errors
3. Verify network connectivity
4. Try password reset if account exists

### 3. **Firebase Initialization Issues**

#### **Problem:** Firebase not properly initialized

#### **Solution Checklist:**
- ✅ `firebase_options.dart` file exists
- ✅ Firebase.initializeApp() called in main()
- ⚠️ Check platform-specific configuration files exist:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`

## 🔍 Debugging Tools

### **Check Logs**
The app now includes detailed logging. Check:
- Debug console output
- Firebase Console → Authentication → Users
- Firebase Console → Authentication → Sign-in methods

### **Test Authentication Steps**

1. **Email/Password Test:**
   ```
   1. Try creating new account first
   2. Use strong password (6+ chars)
   3. Check Firebase Console for user creation
   4. Try signing in with same credentials
   ```

2. **Google Sign-In Test:**
   ```
   1. Clear browser cache/cookies
   2. Try in incognito/private mode
   3. Check browser console for errors
   4. Verify popup blocker is disabled
   ```

## 🛠️ Manual Configuration Steps

### **If Issues Persist:**

1. **Re-run FlutterFire Configuration:**
   ```bash
   flutterfire configure --project=auracare-01
   ```

2. **Verify Firebase Project Settings:**
   - Project ID: `auracare-01`
   - Authentication providers enabled
   - Authorized domains configured

3. **Check Platform-Specific Setup:**

   **Android:**
   ```bash
   # Verify google-services.json exists
   ls android/app/google-services.json
   
   # Check application ID matches
   grep "package_name" android/app/google-services.json
   ```

   **Web:**
   ```bash
   # Verify index.html contains client ID
   grep "google-signin-client_id" web/index.html
   ```

4. **Clean and Rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 📞 Emergency Access

### **If Still Cannot Sign In:**

1. **Use Password Reset:**
   - Click "Forgot Password?" on sign-in screen
   - Enter your email
   - Check email for reset link

2. **Create New Account:**
   - Use "Sign Up" instead of "Sign In"
   - Verify email format is correct
   - Use strong password

3. **Check Firebase Console:**
   - Go to Firebase Console → Authentication → Users
   - Verify if user was created
   - Check sign-in method used

## 🔒 Security Notes

- Never share Firebase configuration files publicly
- Client IDs in web configuration are safe to expose
- Server keys should never be in client code
- All authentication is handled securely by Firebase

## 📱 Platform-Specific Notes

### **Web Platform**
- Requires meta tag in index.html
- Popup blockers can interfere
- CORS issues may occur on localhost

### **Mobile Platforms**
- Requires platform-specific config files
- iOS requires bundle ID to match Firebase project
- Android requires package name to match Firebase project

---

**Need More Help?**
- Check [Firebase Documentation](https://firebase.google.com/docs/auth)
- Review [FlutterFire Documentation](https://firebase.flutter.dev/)
- Check project's GitHub Issues
