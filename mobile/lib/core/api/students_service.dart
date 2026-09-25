import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/student.dart';
import '../constants.dart';
import 'api_client.dart';

/// Service for student-related API calls
class StudentsService {
  final ApiClient _apiClient;

  StudentsService(this._apiClient);

  /// Get all students for the current family
  Future<List<Student>> getAll() async {
    try {
      final response = await _apiClient.get(ApiConstants.students);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Student.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single student by ID
  Future<Student> getById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.students}/$id');
      return Student.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new student
  Future<Student> create({
    required String name,
    required String gradeLevel,
    String? avatarColor,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.students,
        data: {
          'name': name,
          'gradeLevel': gradeLevel,
          if (avatarColor != null) 'avatarColor': avatarColor,
        },
      );
      return Student.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing student
  Future<Student> update(
    String id, {
    String? name,
    String? gradeLevel,
    String? avatarColor,
    bool? active,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.students}/$id',
        data: {
          if (name != null) 'name': name,
          if (gradeLevel != null) 'gradeLevel': gradeLevel,
          if (avatarColor != null) 'avatarColor': avatarColor,
          if (active != null) 'active': active,
        },
      );
      return Student.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a student (soft delete)
  Future<void> delete(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.students}/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException e) {
    final message = e.response?.data?['error'] ??
        e.response?.data?['message'] ??
        e.message ??
        'Failed to fetch students';
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}

/// API exception with optional status code
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Provider for StudentsService
final studentsServiceProvider = Provider<StudentsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StudentsService(apiClient);
},);
