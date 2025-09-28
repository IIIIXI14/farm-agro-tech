# Phone Authentication Setup Guide

## Error Analysis
The error indicates two main issues:
1. **Phone sign-in provider is disabled** in Firebase Console
2. **No AppCheckProvider installed** for security

## Step 1: Enable Phone Authentication in Firebase Console

### 1.1 Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `farmagrotech-7d3a7`
3. Go to **Authentication** → **Sign-in method**

### 1.2 Enable Phone Authentication
1. Find **Phone** in the sign-in providers list
2. Click on **Phone** to open settings
3. Toggle **Enable** to ON
4. Click **Save**

### 1.3 Configure Phone Authentication (Optional)
- **Test phone numbers**: Add test phone numbers for development
- **App verification**: Configure reCAPTCHA settings
- **Quota limits**: Set up usage quotas if needed

## Step 2: Configure Firebase App Check

### 2.1 Enable App Check in Firebase Console
1. Go to **Project Settings** → **App Check**
2. Click **Get started**
3. Select your Android app
4. Choose **Play Integrity API** (recommended for Android)
5. Follow the setup instructions

### 2.2 Alternative: Disable App Check for Development
If you want to disable App Check for development:
1. Go to **Project Settings** → **App Check**
2. Click on your app
3. Toggle **Enforce** to OFF (for development only)

## Step 3: Update Android Configuration

### 3.1 Update google-services.json
Make sure your `android/app/google-services.json` file is up to date:
1. Go to **Project Settings** → **General**
2. Scroll down to **Your apps**
3. Click on your Android app
4. Download the latest `google-services.json`
5. Replace the file in `android/app/`

### 3.2 Update Android Manifest
Add phone authentication permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
```

## Step 4: Test Phone Authentication

### 4.1 Test with Real Phone Number
1. Use a real phone number (not test number)
2. Make sure the phone can receive SMS
3. Try the authentication flow

### 4.2 Test with Test Phone Numbers (Development)
1. In Firebase Console → Authentication → Sign-in method → Phone
2. Add test phone numbers in the format: `+1234567890`
3. Use verification code: `123456`
4. Test the flow with these numbers

## Step 5: Troubleshooting

### 5.1 Common Issues
- **"This operation is not allowed"**: Phone auth not enabled
- **"No AppCheckProvider"**: App Check not configured
- **"Invalid phone number"**: Check phone number format
- **"SMS not received"**: Check phone number and carrier

### 5.2 Debug Steps
1. Check Firebase Console for enabled providers
2. Verify google-services.json is updated
3. Check Android permissions
4. Test with different phone numbers
5. Check Firebase project quotas

## Step 6: Production Considerations

### 6.1 Security
- Enable App Check for production
- Set up proper quotas
- Monitor usage and abuse
- Use test phone numbers only in development

### 6.2 Performance
- Implement proper error handling
- Add retry mechanisms
- Cache verification IDs
- Handle network failures

## Quick Fix Commands

### Enable Phone Auth via Firebase CLI (Alternative)
```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Enable phone authentication (if supported)
firebase auth:enable phone
```

### Check Current Configuration
```bash
# Check Firebase project configuration
firebase projects:list
firebase use farmagrotech-7d3a7
firebase auth:export users.json
```

## Support
If issues persist:
1. Check Firebase Console for error logs
2. Verify project configuration
3. Test with Firebase Auth emulator
4. Contact Firebase support if needed
