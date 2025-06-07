class AppConfig {
  final String? env;
  final bool? production;
  final String? baseUrl;

  final String? socketUrl;
  final String? appName;
  static AppConfig? _singleton;

  AppConfig({
    this.env,
    this.production,
    this.baseUrl,
    this.socketUrl,
    this.appName,
  });

  static void fromJson(config) {
    _singleton = AppConfig(
      env: config['env'],
      production: config['production'],
      baseUrl: config['baseUrl'],
      socketUrl: config['socketUrl'],
      appName: config['appName'],
    );
  }

  static Future<AppConfig?> forEnvironment(String env) async {
    String path = env;
    return _singleton;
  }

  static AppConfig? instance() => _singleton;
}
