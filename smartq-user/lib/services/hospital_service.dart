import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/hospital_model.dart';
import 'api_service.dart';

class HospitalService {
  HospitalService({
    ApiService? apiService,
  }) : _api = apiService ?? ApiService();

  final ApiService _api;

  /*
  |--------------------------------------------------------------------------
  | Get All Hospitals
  |--------------------------------------------------------------------------
  */

  Future<List<HospitalModel>> getHospitals() async {
    try {
      final Response<dynamic> response =
      await _api.dio.get(
        '/hospitals',
      );

      final List<dynamic> hospitalData =
      _extractList(
        response.data,
        propertyName: 'hospitals',
      );

      return hospitalData
          .whereType<Map>()
          .map(
            (dynamic item) =>
            HospitalModel.fromJson(
              Map<String, dynamic>.from(
                item as Map,
              ),
            ),
      )
          .toList();
    } on DioException catch (error) {
      debugPrint(
        'Hospital loading Dio error: $error',
      );

      throw Exception(
        _getErrorMessage(
          error,
          fallback:
          'Failed to load hospitals',
        ),
      );
    } catch (error) {
      debugPrint(
        'Hospital loading error: $error',
      );

      throw Exception(
        'Failed to load hospitals',
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Get Hospitals with Department Counts
  |--------------------------------------------------------------------------
  |
  | This is useful for the home screen:
  |
  | Colombo National Hospital
  | 6 Departments
  |
  */

  Future<List<HospitalSummary>>
  getHospitalsWithDepartmentCounts() async {
    try {
      final Response<dynamic> response =
      await _api.dio.get(
        '/hospitals',
      );

      final List<dynamic> hospitalData =
      _extractList(
        response.data,
        propertyName: 'hospitals',
      );

      final List<HospitalSummary> results =
      await Future.wait(
        hospitalData
            .whereType<Map>()
            .map(
              (dynamic item) async {
            final Map<String, dynamic>
            hospitalJson =
            Map<String, dynamic>.from(
              item as Map,
            );

            final HospitalModel hospital =
            HospitalModel.fromJson(
              hospitalJson,
            );

            final String hospitalId =
                hospitalJson['_id']
                    ?.toString()
                    .trim() ??
                    hospitalJson['id']
                        ?.toString()
                        .trim() ??
                    '';

            int departmentCount =
            _parseInteger(
              hospitalJson[
              'departmentCount'],
            );

            if (!hospitalJson.containsKey(
              'departmentCount',
            ) &&
                hospitalId.isNotEmpty) {
              departmentCount =
              await getDepartmentCount(
                hospitalId,
              );
            }

            return HospitalSummary(
              hospital: hospital,
              departmentCount:
              departmentCount,
              rawData: hospitalJson,
            );
          },
        ),
      );

      return results;
    } on DioException catch (error) {
      debugPrint(
        'Hospital summary Dio error: $error',
      );

      throw Exception(
        _getErrorMessage(
          error,
          fallback:
          'Failed to load hospitals',
        ),
      );
    } catch (error) {
      debugPrint(
        'Hospital summary error: $error',
      );

      throw Exception(
        error
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Get Departments for a Hospital
  |--------------------------------------------------------------------------
  */

  Future<List<Map<String, dynamic>>>
  getDepartmentsByHospital(
      String hospitalId,
      ) async {
    final String normalizedHospitalId =
    hospitalId.trim();

    if (normalizedHospitalId.isEmpty) {
      throw ArgumentError(
        'Hospital ID is required',
      );
    }

    try {
      final Response<dynamic> response =
      await _api.dio.get(
        '/departments/$normalizedHospitalId',
      );

      final List<dynamic> departmentData =
      _extractList(
        response.data,
        propertyName: 'departments',
      );

      return departmentData
          .whereType<Map>()
          .map(
            (dynamic item) =>
        Map<String, dynamic>.from(
          item as Map,
        ),
      )
          .toList();
    } on DioException catch (error) {
      debugPrint(
        'Department loading Dio error: '
            '$error',
      );

      throw Exception(
        _getErrorMessage(
          error,
          fallback:
          'Failed to load departments',
        ),
      );
    } catch (error) {
      debugPrint(
        'Department loading error: '
            '$error',
      );

      throw Exception(
        'Failed to load departments',
      );
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Get Department Count
  |--------------------------------------------------------------------------
  */

  Future<int> getDepartmentCount(
      String hospitalId,
      ) async {
    try {
      final List<Map<String, dynamic>>
      departments =
      await getDepartmentsByHospital(
        hospitalId,
      );

      return departments.length;
    } catch (error) {
      debugPrint(
        'Department count error for '
            '$hospitalId: $error',
      );

      return 0;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Find Hospital by ID
  |--------------------------------------------------------------------------
  */

  Future<HospitalModel?> getHospitalById(
      String hospitalId,
      ) async {
    final String normalizedHospitalId =
    hospitalId.trim();

    if (normalizedHospitalId.isEmpty) {
      return null;
    }

    try {
      final List<HospitalModel> hospitals =
      await getHospitals();

      for (final HospitalModel hospital
      in hospitals) {
        final dynamic hospitalData =
            hospital;

        try {
          final String currentId =
              hospitalData.id
                  ?.toString()
                  .trim() ??
                  '';

          if (currentId ==
              normalizedHospitalId) {
            return hospital;
          }
        } catch (_) {
          // Continue searching when the model
          // does not expose an `id` property.
        }
      }

      return null;
    } catch (error) {
      debugPrint(
        'Hospital lookup error: $error',
      );

      rethrow;
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Response Helpers
  |--------------------------------------------------------------------------
  */

  List<dynamic> _extractList(
      dynamic value, {
        required String propertyName,
      }) {
    if (value is List) {
      return value;
    }

    if (value is Map &&
        value[propertyName] is List) {
      return List<dynamic>.from(
        value[propertyName] as List,
      );
    }

    return [];
  }

  int _parseInteger(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  String _getErrorMessage(
      DioException error, {
        required String fallback,
      }) {
    final dynamic responseData =
        error.response?.data;

    if (responseData is Map) {
      final dynamic message =
      responseData['message'];

      if (message != null &&
          message
              .toString()
              .trim()
              .isNotEmpty) {
        return message
            .toString()
            .trim();
      }
    }

    if (error.type ==
        DioExceptionType
            .connectionTimeout) {
      return 'Connection timed out';
    }

    if (error.type ==
        DioExceptionType
            .receiveTimeout) {
      return 'The server took too long to respond';
    }

    if (error.type ==
        DioExceptionType
            .connectionError) {
      return 'Unable to connect to the server';
    }

    return fallback;
  }
}

/*
|--------------------------------------------------------------------------
| Hospital Summary
|--------------------------------------------------------------------------
|
| Contains the hospital model together with its real department count.
|
*/

class HospitalSummary {
  const HospitalSummary({
    required this.hospital,
    required this.departmentCount,
    required this.rawData,
  });

  final HospitalModel hospital;
  final int departmentCount;
  final Map<String, dynamic> rawData;

  String get id =>
      rawData['_id']
          ?.toString()
          .trim() ??
          rawData['id']
              ?.toString()
              .trim() ??
          '';

  String get name =>
      rawData['name']
          ?.toString()
          .trim() ??
          'Unnamed Hospital';

  String get city =>
      rawData['city']
          ?.toString()
          .trim() ??
          rawData['location']
              ?.toString()
              .trim() ??
          '';

  Map<String, dynamic> toJson() {
    return {
      ...rawData,
      'departmentCount':
      departmentCount,
    };
  }
}