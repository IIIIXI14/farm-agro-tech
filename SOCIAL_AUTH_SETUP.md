# Social Authentication Setup Guide

## Overview
This guide will help you set up Google, Facebook, and Apple authentication for your Farm Agro Tech app.

## Dependencies Added
- `google_sign_in: ^6.2.1` - Google Sign-In
- `sign_in_with_apple: ^6.1.0` - Apple Sign-In
- `flutter_facebook_auth: ^6.0.4` - Facebook Sign-In

## 1. Google Sign-In Setup

### 1.1 Firebase Console Configuration
1. Go to [Firebase Console](https://console.firebase.google.com/project/farmagrotech-7d3a7)
2. Navigate to **Authentication** → **Sign-in method**
3. Find **Google** in the providers list
4. Click on **Google** and toggle **Enable** to ON
5. Set **Project support email** (required)
6. Click **Save**

### 1.2 Android Configuration
1. **Download google-services.json**:
   - Go to **Project Settings** → **General**
   - Download the latest `google-services.json`
   - Replace the file in `android/app/`

2. **Add SHA-1 fingerprint** (for release builds):
   ```bash
   # Debug SHA-1
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release SHA-1 (if you have a release keystore)
   keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
   ```
   - Add SHA-1 to Firebase Console → Project Settings → General → Your apps

### 1.3 iOS Configuration
1. **Download GoogleService-Info.plist**:
   - Go to **Project Settings** → **General**
   - Download `GoogleService-Info.plist`
   - Add to `ios/Runner/` in Xcode

2. **Add URL Scheme**:
   - Open `ios/Runner/Info.plist`
   - Add your REVERSED_CLIENT_ID:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>REVERSED_CLIENT_ID</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>YOUR_REVERSED_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

## 2. Facebook Sign-In Setup

### 2.1 Facebook Developer Console
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app or use existing app
3. Add **Facebook Login** product
4. Configure **Facebook Login** settings

### 2.2 Firebase Console Configuration
1. Go to **Authentication** → **Sign-in method**
2. Find **Facebook** in the providers list
3. Click on **Facebook** and toggle **Enable** to ON
4. Enter your **App ID** and **App Secret** from Facebook Developer Console
5. Click **Save**

### 2.3 Android Configuration
1. **Add to android/app/src/main/AndroidManifest.xml**:
   ```xml
   <meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id"/>
   <meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/facebook_client_token"/>
   ```

2. **Add to android/app/src/main/res/values/strings.xml**:
   ```xml
   <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
   <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
   ```

3. **Add to android/app/src/main/AndroidManifest.xml** (in application tag):
   ```xml
   <activity android:name="com.facebook.FacebookActivity"
       android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
       android:label="@string/app_name" />
   <activity
       android:name="com.facebook.CustomTabActivity"
       android:exported="true">
       <intent-filter>
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data android:scheme="@string/fb_login_protocol_scheme" />
       </intent-filter>
   </activity>
   ```

### 2.4 iOS Configuration
1. **Add to ios/Runner/Info.plist**:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>facebook</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>fbYOUR_FACEBOOK_APP_ID</string>
           </array>
       </dict>
   </array>
   <key>FacebookAppID</key>
   <string>YOUR_FACEBOOK_APP_ID</string>
   <key>FacebookClientToken</key>
   <string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
   <key>FacebookDisplayName</key>
   <string>Farm Agro Tech</string>
   ```

## 3. Apple Sign-In Setup

### 3.1 Apple Developer Console
1. Go to [Apple Developer Console](https://developer.apple.com/)
2. Enable **Sign In with Apple** capability
3. Configure your app identifier

### 3.2 Firebase Console Configuration
1. Go to **Authentication** → **Sign-in method**
2. Find **Apple** in the providers list
3. Click on **Apple** and toggle **Enable** to ON
4. Enter your **Services ID** and **Apple Team ID**
5. Click **Save**

### 3.3 iOS Configuration
1. **Add capability in Xcode**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target
   - Go to **Signing & Capabilities**
   - Add **Sign In with Apple** capability

2. **Add to ios/Runner/Info.plist**:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>apple</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>YOUR_BUNDLE_ID</string>
           </array>
       </dict>
   </array>
   ```

## 4. Testing

### 4.1 Test Accounts
- **Google**: Use any Google account
- **Facebook**: Use test users from Facebook Developer Console
- **Apple**: Use any Apple ID (iOS only)

### 4.2 Debug Steps
1. Check Firebase Console for enabled providers
2. Verify configuration files are updated
3. Test on both Android and iOS
4. Check console logs for errors

## 5. Production Considerations

### 5.1 Security
- Use proper SHA-1 fingerprints for release builds
- Configure OAuth redirect URIs correctly
- Set up proper app review processes

### 5.2 User Experience
- Handle sign-in cancellations gracefully
- Provide fallback options
- Show appropriate error messages

## 6. Troubleshooting

### Common Issues
- **"Sign-in failed"**: Check provider configuration
- **"Invalid client"**: Verify OAuth credentials
- **"App not configured"**: Check bundle ID/package name
- **"Network error"**: Check internet connection

### Debug Commands
```bash
# Check Firebase configuration
firebase projects:list
firebase use farmagrotech-7d3a7

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 7. Files Modified
- ✅ `pubspec.yaml` - Added social auth dependencies
- ✅ `lib/services/social_auth_service.dart` - Social auth service
- ✅ `lib/screens/login_screen.dart` - Added social login buttons
- ✅ `lib/screens/register_screen.dart` - Added social login buttons

## 8. Next Steps
1. Configure each provider in Firebase Console
2. Update platform-specific configuration files
3. Test authentication flows
4. Deploy to production with proper credentials
