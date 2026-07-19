import 'package:firebase_auth/firebase_auth.dart';

import 'api_service.dart';

class ProfileService {
  final ApiService api = ApiService();

  Future<Map<String, dynamic>> syncProfile({
    String? name,
    String? phone,
  }) async {
    final User? firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    final response = await api.dio.post(
      '/profile/sync',
      data: {
        'name':
        name?.trim().isNotEmpty == true
            ? name!.trim()
            : firebaseUser.displayName
            ?.trim()
            .isNotEmpty ==
            true
            ? firebaseUser.displayName!.trim()
            : 'Patient',
        'email':
        firebaseUser.email?.trim() ?? '',
        'phone':
        phone?.trim().isNotEmpty == true
            ? phone!.trim()
            : firebaseUser.phoneNumber
            ?.trim() ??
            '',
        'photoUrl':
        firebaseUser.photoURL?.trim() ?? '',
      },
    );

    final dynamic responseData =
        response.data;

    if (responseData is! Map ||
        responseData['user'] is! Map) {
      throw Exception(
        'Invalid profile synchronization response',
      );
    }

    return Map<String, dynamic>.from(
      responseData['user'] as Map,
    );
  }

  Future<Map<String, dynamic>>
  getProfile() async {
    final response = await api.dio.get(
      '/profile',
    );

    final dynamic responseData =
        response.data;

    if (responseData is! Map) {
      throw Exception(
        'Invalid profile response',
      );
    }

    return Map<String, dynamic>.from(
      responseData,
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
  }) async {
    final String normalizedName =
    name.trim();

    final String normalizedPhone =
    phone.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError(
        'Name is required',
      );
    }

    if (normalizedPhone.isEmpty) {
      throw ArgumentError(
        'Phone number is required',
      );
    }

    final response = await api.dio.put(
      '/profile',
      data: {
        'name': normalizedName,
        'phone': normalizedPhone,
      },
    );

    final dynamic responseData =
        response.data;

    if (responseData is! Map ||
        responseData['user'] is! Map) {
      throw Exception(
        'Invalid profile update response',
      );
    }

    return Map<String, dynamic>.from(
      responseData['user'] as Map,
    );
  }

  /// Registers this device's Firebase Cloud Messaging token.
  ///
  /// The backend uses `$addToSet`, so an existing token will
  /// not be added more than once.
  Future<void> updateFcmToken(
      String fcmToken,
      ) async {
    final String token =
    fcmToken.trim();

    if (token.isEmpty) {
      throw ArgumentError(
        'FCM token is required',
      );
    }

    await api.dio.put(
      '/profile/fcm-token',
      data: {
        'fcmToken': token,
      },
    );
  }

  /// Removes only this device's Firebase Cloud Messaging token.
  ///
  /// This does not delete the Firebase account and does not
  /// remove tokens belonging to the user's other devices.
  Future<void> removeFcmToken(
      String fcmToken,
      ) async {
    final String token =
    fcmToken.trim();

    if (token.isEmpty) {
      return;
    }

    await api.dio.delete(
      '/profile/fcm-token',
      data: {
        'fcmToken': token,
      },
    );
  }
}