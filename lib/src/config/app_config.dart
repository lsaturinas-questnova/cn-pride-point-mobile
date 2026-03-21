class AppConfig {
  const AppConfig({
    required this.oauthClientId,
    required this.oauthClientSecret,
  });

  final String oauthClientId;
  final String oauthClientSecret;

  static AppConfig fromDartDefines() {
    const id = String.fromEnvironment(
      'OAUTH_CLIENT_ID',
      defaultValue: 'cnpp-mobile',
    );
    const secret = String.fromEnvironment(
      'OAUTH_CLIENT_SECRET',
      defaultValue: 'cnpp-mobile-secret',
    );

    return AppConfig(oauthClientId: id, oauthClientSecret: secret);
  }
}
