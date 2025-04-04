import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Configure GoogleSignIn with scopes and client ID for web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web client ID is only needed for web platforms
    clientId: kIsWeb ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' : null,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // For web, we can use Firebase's signInWithPopup for a better experience
      if (kIsWeb) {
        // Web sign-in flow
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.addScope('email');
        authProvider.addScope('profile');
        
        try {
          // Try popup first (better user experience)
          final userCredential = await _auth.signInWithPopup(authProvider);
          
          // If this is a new user, create a user document in Firestore
          if (userCredential.additionalUserInfo?.isNewUser ?? false) {
            await _createUserDocument(userCredential.user!);
          }
          
          return userCredential;
        } catch (e) {
          // Fall back to redirect if popup fails
          await _auth.signInWithRedirect(authProvider);
          return null; // This will return after redirect completes
        }
      } else {
        // Mobile sign-in flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        
        // If this is a new user, create a user document in Firestore
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createUserDocument(userCredential.user!);
        }

        return userCredential;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Create a user document in Firestore
  Future<void> _createUserDocument(User user) async {
    final appUser = AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
    );

    await _firestore.collection('users').doc(user.uid).set(appUser.toJson());
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData() async {
    if (currentUser == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  // Get user data from Firestore for a specific user ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get Firestore instance (for use in other services)
  FirebaseFirestore get firestore => _firestore;
}