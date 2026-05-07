class AppConstants {
  // ─── API ────────────────────────────────────────────────────────────────────
  static const bool useDev = false;

  static const String baseUrl = 'https://api.tezyubor.uz/api';

  // Для Android эмулятора 10.0.2.2 = localhost хоста
  // Для физического устройства замени на IP своего ПК: http://192.168.1.X:5000/api
  static const String devBaseUrl = 'http://10.0.2.2:5000/api';

  static String get apiUrl => useDev ? devBaseUrl : baseUrl;

  // ─── Yandex Maps ─────────────────────────────────────────────────────────────
  static const String yandexMapsKey = '1422898e-3abb-4ce2-b9b7-d419e33da9f8';
  static const String yandexSuggestKey = 'b7353a53-e07d-4814-a535-96e6ac470a8e';

  // ─── Storage keys ────────────────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String themeKey = 'app_theme';
  static const String localeKey = 'app_locale';
  static const String environmentKey = 'app_environment';

  // ─── App config ──────────────────────────────────────────────────────────────
  static const int logoTapCountToSwitchEnv = 5;
}
