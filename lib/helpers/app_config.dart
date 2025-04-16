class AppConfig {
  final String? env;
  final bool? production;
  final String? baseUrl;

  final String? websiteUrl;
  final String? appName;
  static AppConfig? _singleton;

  AppConfig({
    this.env,
    this.production,
    this.baseUrl,
    this.websiteUrl,
    this.appName,
  });

  static void fromJson(config) {
    _singleton = AppConfig(
      env: config['env'],
      production: config['production'],
      baseUrl: config['baseUrl'],
      websiteUrl: config['websiteUrl'],
      appName: config['appName'],
    );
  }

  static Future<AppConfig?> forEnvironment(String env) async {
    String path = env;
    return _singleton;
  }

  static AppConfig? instance() => _singleton;
}
