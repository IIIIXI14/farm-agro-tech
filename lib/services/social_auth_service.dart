import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SocialAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FacebookAuth _facebookAuth = FacebookAuth.instance;

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Save user data to Firestore
      await _saveUserData(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Facebook Sign-In
  static Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await _facebookAuth.login();
      
      if (result.status == LoginStatus.success) {
        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential = 
            FacebookAuthProvider.credential(result.accessToken!.token);

        // Sign in to Firebase with the Facebook credential
        final UserCredential userCredential = 
            await _auth.signInWithCredential(facebookAuthCredential);
        
        // Save user data to Firestore
        await _saveUserData(userCredential.user!);
        
        return userCredential;
      } else if (result.status == LoginStatus.cancelled) {
        // User cancelled the sign-in
        return null;
      } else {
        throw Exception('Facebook sign-in failed: ${result.message}');
      }
    } catch (e) {
      throw Exception('Facebook sign-in failed: $e');
    }
  }

  // Apple Sign-In
  static Future<UserCredential?> signInWithApple() async {
    try {
      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(oauthCredential);
      
      // Save user data to Firestore
      await _saveUserData(userCredential.user!);
      
      return userCredential;
    } catch (e) {
      throw Exception('Apple sign-in failed: $e');
    }
  }

  // Save user data to Firestore
  static Future<void> _saveUserData(User user) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Check if user document already exists
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        // Create new user document
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'loginMethod': _getLoginMethod(user),
        });
      } else {
        // Update existing user document
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'loginMethod': _getLoginMethod(user),
        });
      }
    } catch (e) {
      print('Error saving user data: $e');
      // Don't throw error here as user is already signed in
    }
  }

  // Determine login method based on provider
  static String _getLoginMethod(User user) {
    if (user.providerData.any((provider) => provider.providerId == 'google.com')) {
      return 'google';
    } else if (user.providerData.any((provider) => provider.providerId == 'facebook.com')) {
      return 'facebook';
    } else if (user.providerData.any((provider) => provider.providerId == 'apple.com')) {
      return 'apple';
    } else if (user.providerData.any((provider) => provider.providerId == 'phone')) {
      return 'phone';
    } else {
      return 'email';
    }
  }

  // Sign out from all providers
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _facebookAuth.logOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  // Get current user
  static User? get currentUser => _auth.currentUser;
}
