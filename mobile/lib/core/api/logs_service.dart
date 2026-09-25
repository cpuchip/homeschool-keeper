import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/log_entry.dart';
import '../constants.dart';
import 'api_client.dart';
import 'students_service.dart';

/// Service for log entry-related API calls
class LogsService {
  final ApiClient _apiClient;

  LogsService(this._apiClient);

  /// Get all logs for the current family
  /// Optional filters: studentId, subjectId, schoolYear, startDate, endDate
  Future<List<LogEntry>> getAll({
    String? studentId,
    String? subjectId,
    String? schoolYear,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (studentId != null) queryParams['studentId'] = studentId;
      if (subjectId != null) queryParams['subjectId'] = subjectId;
      if (schoolYear != null) queryParams['schoolYear'] = schoolYear;
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get(
        ApiConstants.logs,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => LogEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single log entry by ID
  Future<LogEntry> getById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.logs}/$id');
      return LogEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new log entry
  Future<LogEntry> create({
    required String studentId,
    required String subjectId,
    required DateTime date,
    required double hours,
    String? description,
    String locationType = 'home',
    String? locationName,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.logs,
        data: {
          'studentId': studentId,
          'subjectId': subjectId,
          'date': date.toIso8601String(),
          'hours': hours,
          'description': description ?? '',
          'locationType': locationType,
          if (locationName != null) 'locationName': locationName,
        },
      );
      return LogEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing log entry
  Future<LogEntry> update(
    String id, {
    String? studentId,
    String? subjectId,
    DateTime? date,
    double? hours,
    String? description,
    String? locationType,
    String? locationName,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.logs}/$id',
        data: {
          if (studentId != null) 'studentId': studentId,
          if (subjectId != null) 'subjectId': subjectId,
          if (date != null) 'date': date.toIso8601String(),
          if (hours != null) 'hours': hours,
          if (description != null) 'description': description,
          if (locationType != null) 'locationType': locationType,
          if (locationName != null) 'locationName': locationName,
        },
      );
      return LogEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a log entry
  Future<void> delete(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.logs}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    final message = e.response?.data?['error'] ??
        e.response?.data?['message'] ??
        e.message ??
        'Failed to fetch logs';
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}

/// Provider for LogsService
final logsServiceProvider = Provider<LogsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LogsService(apiClient);
},);
