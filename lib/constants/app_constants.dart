class AppConstants {
  // App Information
  static const String appName = 'Ryde';
  static const String appTagline = 'The best car in your hands with Ryde App.';

  // Storage Keys
  static const String isFirstTimeKey = 'is_first_time';
  static const String userIdKey = 'user_id';
  static const String authTokenKey = 'auth_token';

  // Validation Patterns
  static final RegExp emailPattern = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );
  static final RegExp phonePattern = RegExp(r'^\d{10}$');
  static final RegExp aadhaarPattern = RegExp(r'^\d{12}$');

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String ridesCollection = 'rides';
  static const String bookingsCollection = 'bookings';

  // Error Messages
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String authErrorMessage =
      'Authentication failed. Please try again.';
}
