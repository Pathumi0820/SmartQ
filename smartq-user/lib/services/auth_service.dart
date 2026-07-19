import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'profile_service.dart';

class AuthService {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  final GoogleSignIn _googleSignIn =
  GoogleSignIn();

  final ProfileService _profileService =
  ProfileService();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  bool get isLoggedIn =>
      _auth.currentUser != null;

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final String normalizedEmail =
    email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw ArgumentError(
        'Email is required',
      );
    }

    if (password.isEmpty) {
      throw ArgumentError(
        'Password is required',
      );
    }

    if (password.length < 6) {
      throw ArgumentError(
        'Password must contain at least 6 characters',
      );
    }

    return _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final String normalizedEmail =
    email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw ArgumentError(
        'Email is required',
      );
    }

    if (password.isEmpty) {
      throw ArgumentError(
        'Password is required',
      );
    }

    return _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser =
    await _googleSignIn.signIn();

    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;

    final OAuthCredential credential =
    GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final UserCredential userCredential =
    await _auth.signInWithCredential(
      credential,
    );

    final User? user =
        userCredential.user;

    if (user != null) {
      await _saveGoogleUserToFirestore(
        user,
      );
    }

    return userCredential;
  }

  Future<void> _saveGoogleUserToFirestore(
      User user,
      ) async {
    final DocumentReference<Map<String, dynamic>>
    userDocument = _firestore
        .collection('users')
        .doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>>
    existingDocument =
    await userDocument.get();

    final Map<String, dynamic> data = {
      'uid': user.uid,
      'fullName':
      user.displayName?.trim() ?? '',
      'email':
      user.email?.trim() ?? '',
      'phone':
      user.phoneNumber?.trim() ?? '',
      'profileImage':
      user.photoURL?.trim() ?? '',
      'role': 'patient',
      'updatedAt':
      FieldValue.serverTimestamp(),
    };

    if (!existingDocument.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    await userDocument.set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<void> saveUserToFirestore({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final String normalizedUid =
    uid.trim();

    final String normalizedName =
    fullName.trim();

    final String normalizedEmail =
    email.trim().toLowerCase();

    final String normalizedPhone =
    phone.trim();

    if (normalizedUid.isEmpty) {
      throw ArgumentError(
        'User ID is required',
      );
    }

    if (normalizedName.isEmpty) {
      throw ArgumentError(
        'Full name is required',
      );
    }

    if (normalizedEmail.isEmpty) {
      throw ArgumentError(
        'Email is required',
      );
    }

    final DocumentReference<Map<String, dynamic>>
    userDocument = _firestore
        .collection('users')
        .doc(normalizedUid);

    final DocumentSnapshot<Map<String, dynamic>>
    existingDocument =
    await userDocument.get();

    final Map<String, dynamic> data = {
      'uid': normalizedUid,
      'fullName': normalizedName,
      'email': normalizedEmail,
      'phone': normalizedPhone,
      'profileImage': '',
      'role': 'patient',
      'updatedAt':
      FieldValue.serverTimestamp(),
    };

    if (!existingDocument.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    await userDocument.set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>>
  getCurrentUserData() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently logged in',
      );
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .get();
  }

  Future<Map<String, dynamic>?>
  getUserData() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
    document = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    return document.data();
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    final String normalizedEmail =
    email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw ArgumentError(
        'Email is required',
      );
    }

    await _auth.sendPasswordResetEmail(
      email: normalizedEmail,
    );
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently logged in',
      );
    }

    final String normalizedName =
    fullName.trim();

    final String normalizedPhone =
    phone.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError(
        'Full name is required',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'fullName': normalizedName,
        'phone': normalizedPhone,
        'updatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await user.updateDisplayName(
      normalizedName,
    );

    await user.reload();
  }

  Future<void> updateExtraUserData(
      Map<String, dynamic> data,
      ) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently logged in',
      );
    }

    if (data.isEmpty) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        ...data,
        'updatedAt':
        FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  Future<void> signOut() async {
    String currentFcmToken = '';

    /*
    |--------------------------------------------------------------------------
    | Read Current Device FCM Token
    |--------------------------------------------------------------------------
    |
    | This token identifies only the current phone or tablet.
    | It must be read before deleteToken() is called.
    |
    */

    try {
      final String? token =
      await _firebaseMessaging.getToken();

      currentFcmToken =
          token?.trim() ?? '';

      if (currentFcmToken.isEmpty) {
        debugPrint(
          'No current FCM token found during logout',
        );
      }
    } catch (error) {
      debugPrint(
        'Failed to read current FCM token: $error',
      );
    }

    /*
    |--------------------------------------------------------------------------
    | Remove Current Device From MongoDB
    |--------------------------------------------------------------------------
    |
    | The user is still authenticated here, so the backend request
    | can include a valid Firebase authentication token.
    |
    */

    if (currentFcmToken.isNotEmpty) {
      try {
        await _profileService.removeFcmToken(
          currentFcmToken,
        );

        debugPrint(
          'Current device FCM token removed from backend',
        );
      } catch (error) {
        debugPrint(
          'Failed to remove backend FCM token: $error',
        );
      }
    }

    /*
    |--------------------------------------------------------------------------
    | Delete Local FCM Token
    |--------------------------------------------------------------------------
    */

    try {
      await _firebaseMessaging.deleteToken();

      debugPrint(
        'Local FCM token deleted',
      );
    } catch (error) {
      debugPrint(
        'Failed to delete local FCM token: $error',
      );
    }

    /*
    |--------------------------------------------------------------------------
    | Sign Out From Google
    |--------------------------------------------------------------------------
    */

    try {
      final bool googleSignedIn =
      await _googleSignIn.isSignedIn();

      if (googleSignedIn) {
        await _googleSignIn.signOut();
      }

      debugPrint(
        'Google session signed out',
      );
    } catch (error) {
      debugPrint(
        'Google sign-out error: $error',
      );
    }

    /*
    |--------------------------------------------------------------------------
    | Sign Out From Firebase
    |--------------------------------------------------------------------------
    */

    await _auth.signOut();

    debugPrint(
      'Firebase user signed out',
    );
  }
}