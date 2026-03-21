class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.hostUrl,
    this.refreshToken,
    this.expiresAt,
  });

  final String hostUrl;
  final String accessToken;
  final String tokenType;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
