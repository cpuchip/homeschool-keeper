import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/subject.dart';
import '../constants.dart';
import 'api_client.dart';
import 'students_service.dart';

/// Service for subject-related API calls
class SubjectsService {
  final ApiClient _apiClient;

  SubjectsService(this._apiClient);

  /// Get all subjects for the current family
  Future<List<Subject>> getAll() async {
    try {
      final response = await _apiClient.get(ApiConstants.subjects);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Subject.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single subject by ID
  Future<Subject> getById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.subjects}/$id');
      return Subject.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new subject
  Future<Subject> create({
    required String name,
    required String type,
    required String color,
    double? targetHours,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.subjects,
        data: {
          'name': name,
          'type': type,
          'color': color,
          if (targetHours != null) 'targetHours': targetHours,
        },
      );
      return Subject.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing subject
  Future<Subject> update(
    String id, {
    String? name,
    String? type,
    String? color,
    double? targetHours,
    int? sortOrder,
    bool? active,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.subjects}/$id',
        data: {
          if (name != null) 'name': name,
          if (type != null) 'type': type,
          if (color != null) 'color': color,
          if (targetHours != null) 'targetHours': targetHours,
          if (sortOrder != null) 'sortOrder': sortOrder,
          if (active != null) 'active': active,
        },
      );
      return Subject.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a subject (soft delete)
  Future<void> delete(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.subjects}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    final message = e.response?.data?['error'] ??
        e.response?.data?['message'] ??
        e.message ??
        'Failed to fetch subjects';
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}

/// Provider for SubjectsService
final subjectsServiceProvider = Provider<SubjectsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubjectsService(apiClient);
},);
