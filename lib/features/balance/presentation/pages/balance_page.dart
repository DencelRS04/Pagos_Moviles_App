import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../../../widgets/ui_utils.dart';

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  bool _cargando = false;
  String _saldo = '';
  String _mensaje = '';
  String _nombreUsuario = '';

  final String baseUrl = 'https://10.0.2.2:7000';

  http.Client get _httpClient {
    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final telefonoGuardado = await _storage.read(key: 'telefono');
    final nombreGuardado = await _storage.read(key: 'nombre_completo');

    if (!mounted) return;

    setState(() {
      _telefonoController.text = telefonoGuardado ?? '';
      _nombreUsuario = nombreGuardado ?? 'Usuario';
    });
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    super.dispose();
  }

  String? validarTelefono(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es obligatorio';
    }

    final telefono = value.trim();

    if (!RegExp(r'^[0-9]{8}$').hasMatch(telefono)) {
      return 'El teléfono debe tener 8 dígitos';
    }

    return null;
  }

  Future<void> consultarSaldo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _saldo = '';
      _mensaje = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final identificacion = await _storage.read(key: 'identificacion');
      final telefono = _telefonoController.text.trim();

      if (token == null || token.isEmpty) {
        setState(() {
          _mensaje = 'No se encontró el token de sesión.';
        });
        return;
      }

      if (identificacion == null || identificacion.isEmpty) {
        setState(() {
          _mensaje = 'No se encontró la identificación del usuario.';
        });
        return;
      }

      final uri = Uri.parse('$baseUrl/gateway/trans/accounts/balance');

      final client = _httpClient;
      final response = await client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'telefono': telefono,
          'identificacion': identificacion,
        }),
      );

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode == 200) {
        String saldoTexto = '';

        if (body is Map<String, dynamic>) {
          if (body['saldo'] != null) {
            saldoTexto = body['saldo'].toString();
          } else if (body['datos'] is Map && body['datos']['saldo'] != null) {
            saldoTexto = body['datos']['saldo'].toString();
          } else if (body['datos'] != null) {
            saldoTexto = body['datos'].toString();
          }
        }

        setState(() {
          _saldo = saldoTexto.isNotEmpty
              ? saldoTexto
              : 'Saldo recibido sin formato esperado';
        });

        if (mounted) {
          UIUtils.showMsg(context, 'Consulta de saldo realizada correctamente');
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _mensaje = 'Sesión expirada o token inválido.';
        });
      } else if (response.statusCode == 400) {
        setState(() {
          _mensaje = body is Map<String, dynamic> && body['descripcion'] != null
              ? body['descripcion'].toString()
              : 'Datos inválidos para consultar saldo.';
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _mensaje = 'No se encontró la cuenta o el usuario asociado.';
        });
      } else {
        setState(() {
          _mensaje = body is Map<String, dynamic> && body['descripcion'] != null
              ? body['descripcion'].toString()
              : 'Error inesperado: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _mensaje = 'Ocurrió un error al consultar el saldo: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimario = Color(0xFF003366);
    const colorAcento = Color(0xFFF57C00);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: colorPrimario,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consulta de saldo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _nombreUsuario,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ingrese el teléfono asociado a pagos móviles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Número de teléfono',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: validarTelefono,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _cargando ? null : consultarSaldo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorAcento,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _cargando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          _cargando ? 'Consultando...' : 'Consultar saldo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_saldo.isNotEmpty)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.attach_money, color: Colors.green),
                  ),
                  title: const Text(
                    'Saldo disponible',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _saldo,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorPrimario,
                      ),
                    ),
                  ),
                ),
              ),
            if (_mensaje.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _mensaje,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
