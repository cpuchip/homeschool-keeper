import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/stats.dart';
import '../constants.dart';
import 'api_client.dart';
import 'students_service.dart';

/// Service for statistics-related API calls
class StatsService {
  final ApiClient _apiClient;

  StatsService(this._apiClient);

  /// Get family-wide statistics
  Future<FamilyStats> getFamilyStats({String? schoolYear}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (schoolYear != null) queryParams['schoolYear'] = schoolYear;

      final response = await _apiClient.get(
        '${ApiConstants.stats}/family',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return FamilyStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get statistics for a specific student
  Future<StudentStats> getStudentStats(
    String studentId, {
    String? schoolYear,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (schoolYear != null) queryParams['schoolYear'] = schoolYear;

      final response = await _apiClient.get(
        '${ApiConstants.stats}/student/$studentId',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return StudentStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    final message = e.response?.data?['error'] ??
        e.response?.data?['message'] ??
        e.message ??
        'Failed to fetch statistics';
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}

/// Provider for StatsService
final statsServiceProvider = Provider<StatsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatsService(apiClient);
},);
