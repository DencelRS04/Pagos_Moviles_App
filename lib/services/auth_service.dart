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

      if (response.statusCode == 201) {
        final loginData = LoginResponse.fromJson(data);

              // DEBUG: Ver qué viene en data
        print('RESPONSE DATA: $data');
        print('nombreCompleto: ${data['nombreCompleto']}');

        // GUARDAR LOS VALORES DE SESIÓN
        await _storage.write(key: 'access_token', value: loginData.accessToken);
        await _storage.write(key: 'refresh_token', value: loginData.refreshToken);
        await _storage.write(key: 'expires_in', value: loginData.expiresIn.toString());
        await _storage.write(key: 'usuarioID', value: loginData.usuarioID.toString());
        await _storage.write(key: 'nombre_completo', value: data['nombreCompleto']?.toString() ?? '');
        await _storage.write(key: 'identificacion', value: data['identificacion']?.toString() ?? '');
        await _storage.write(key: 'clienteId', value: data['clienteId']?.toString() ?? '');

        return loginData;
      } else {
        throw data['descripcion'] ?? "Error de autenticación";
      }
    } catch (e) {
      throw "Error de conexión: $e";
    }
  }

  Future<void> logout() async {
    // Registrar en bitácora (Requerimiento AM2)
    print("BITÁCORA: Logout realizado. Limpiando credenciales.");

    // Borramos solo los datos de sesión para NO borrar el "Recordarme"
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'expires_in');
    await _storage.delete(key: 'usuarioID');
    await _storage.delete(key: 'nombre_completo');
    await _storage.delete(key: 'identificacion');
    await _storage.delete(key: 'clienteId');
  }
}
