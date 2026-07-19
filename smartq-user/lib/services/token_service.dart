import 'package:dio/dio.dart';

import 'api_service.dart';

class TokenService {
  final ApiService api = ApiService();

  /// Create a new queue token
  Future<Map<String, dynamic>> createToken({
    required String patientName,
    required String patientPhone,
    required String hospital,
    required String department,
  }) async {
    try {
      final response = await api.dio.post(
        "/tokens",
        data: {
          "patientName": patientName,
          "patientPhone": patientPhone,
          "hospital": hospital,
          "department": department,
        },
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  /// Get all tokens for the current user's phone number
  Future<List<dynamic>> getTokensByPhone(String phone) async {
    try {
      final response = await api.dio.get(
        "/tokens/phone/$phone",
      );

      return response.data as List<dynamic>;
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  /// Recover the latest active token
  Future<Map<String, dynamic>?> getActiveToken() async {
    try {
      final response = await api.dio.get(
        "/tokens/active",
      );

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw Exception(_extractErrorMessage(error));
    }
  }

  /// Cancel a token
  Future<void> cancelToken(String tokenId) async {
    try {
      await api.dio.put(
        "/tokens/$tokenId/status",
        data: {
          "status": "Cancelled",
        },
      );
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map &&
        data["message"] != null &&
        data["message"].toString().isNotEmpty) {
      return data["message"].toString();
    }

    if (error.message != null &&
        error.message!.isNotEmpty) {
      return error.message!;
    }

    return "Something went wrong";
  }
}