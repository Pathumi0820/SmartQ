import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio dio;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://192.168.8.124:5000/api/mobile',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              final idToken = await user.getIdToken();

              if (idToken != null && idToken.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $idToken';
              }
            }

            handler.next(options);
          } catch (error) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: error,
                message: 'Unable to obtain authentication token',
              ),
            );
          }
        },
      ),
    );
  }
}