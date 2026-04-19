import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/login_response.dart';

class AuthService {
  final String baseUrl = "https://10.0.2.2:7143/auth";
  final _storage = const FlutterSecureStorage();

  http.Client get _httpClient {
    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  Future<LoginResponse?> login(String email, String password) async {
    try {
      final client = _httpClient;
      final response = await client.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'usuario': email,
          'password': password,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final loginData = LoginResponse.fromJson(data);

        await _storage.write(key: 'access_token', value: loginData.accessToken);
        await _storage.write(
          key: 'refresh_token',
          value: loginData.refreshToken,
        );
        await _storage.write(
          key: 'expires_in',
          value: loginData.expiresIn.toString(),
        );
        await _storage.write(
          key: 'usuarioID',
          value: loginData.usuarioID.toString(),
        );

        return loginData;
      } else {
        // Solo mandamos la descripción del error sin el código numérico
        throw data['descripcion'] ?? "Usuario y/o contraseña incorrectos.";
      }
    } catch (e) {
      if (e is SocketException) {
        throw "No hay conexión con el servidor.";
      }
      throw e.toString();
    }
  }

  Future<void> logout() async {
    print("BITÁCORA: Logout realizado.");
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'expires_in');
    await _storage.delete(key: 'usuarioID');
  }
}
