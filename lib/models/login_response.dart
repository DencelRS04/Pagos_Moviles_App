class LoginResponse {
  final int codigo;
  final String descripcion;
  final String accessToken;
  final String refreshToken;
  final int expiresIn; // Faltaba este
  final int usuarioID;

  LoginResponse({
    required this.codigo,
    required this.descripcion,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.usuarioID,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      codigo: json['codigo'],
      descripcion: json['descripcion'],
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresIn: json['Expires_In'] ?? 0,
      usuarioID: json['usuarioID'] ?? 0,
    );
  }
}
