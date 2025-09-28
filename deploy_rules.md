# Deploy Firestore Rules

To fix the Firestore permission error, you need to deploy the security rules to your Firebase project.

## Steps to Deploy:

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase in your project** (if not already done):
   ```bash
   firebase init firestore
   ```

4. **Deploy the Firestore rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Alternative: Deploy via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `farmagrotech-7d3a7`
3. Go to **Firestore Database** → **Rules**
4. Copy the contents of `firestore.rules` file
5. Paste it into the rules editor
6. Click **Publish**

## What the Rules Do:

- **User Data Access**: Users can only read/write their own user document and subcollections
- **Device Management**: Users can manage their own devices and related data
- **Security**: All other access is denied by default
- **Admin Support**: Optional admin role for accessing all data

## After Deployment:

The permission error should be resolved and your app should be able to:
- Read/write user profile data
- Manage devices and sensor readings
- Access automation rules and schedules
- Store logs and notifications

## Testing:

After deploying, test the app to ensure:
1. User can view their profile in settings
2. Device data loads properly
3. No more permission denied errors in logs
