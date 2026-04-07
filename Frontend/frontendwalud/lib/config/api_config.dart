class ApiConfig {
  static const bool   useMock  = false;
  static const String baseUrl  = 'http://127.0.0.1:8000/api/';

  // Auth
  static const String loginEndpoint    = 'auth/login';
  static const String registerEndpoint = 'auth/register';
  static const String logoutEndpoint   = 'auth/logout';
  static const String meEndpoint       = 'auth/me';

  // Recursos
  static const String usersEndpoint        = 'users';
  static const String appointmentsEndpoint = 'appointments';
  static const String paymentsEndpoint     = 'payments';

  // Colores de la marca
  static const String primaryColor   = 'FF4F46E5';
  static const String secondaryColor = 'FF0EA5E9';
  static const String darkBlue       = 'FF1A1A7A';
  static const String teal           = 'FF06B6D4';
}