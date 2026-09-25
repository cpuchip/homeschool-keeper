/// API configuration constants
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  
  static const Duration timeout = Duration(seconds: 30);
  
  // Mobile auth endpoints (JWT-based)
  static const String mobileLogin = '/mobile/auth/login';
  static const String mobileRegister = '/mobile/auth/register';
  static const String mobileRefresh = '/mobile/auth/refresh';
  static const String mobileMe = '/mobile/auth/me';
  
  // Google OAuth endpoint (shared between web/mobile)
  static const String googleAuth = '/auth/google';
  
  // Legacy web auth endpoints (cookie-based, not used by mobile)
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  
  // Resource endpoints
  static const String students = '/students';
  static const String subjects = '/subjects';
  static const String logs = '/logs';
  static const String yearlyRecords = '/yearly-records';
  static const String stats = '/stats';
  static const String onboarding = '/onboarding';
}

/// Google Sign-In configuration
class GoogleAuthConfig {
  // Client ID is the same for all platforms (web client ID works for ID tokens)
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '729373409476-9dsn6nnpuruhqc5v7tbdurmfi9ss39dk.apps.googleusercontent.com',
  );
}
