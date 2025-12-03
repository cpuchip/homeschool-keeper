/// API configuration constants
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  
  static const Duration timeout = Duration(seconds: 30);
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  
  // Resource endpoints
  static const String students = '/students';
  static const String subjects = '/subjects';
  static const String logs = '/logs';
  static const String yearlyRecords = '/yearly-records';
}
