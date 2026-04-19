import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../../../widgets/ui_utils.dart';
import '../../data/models/wallet_association_response.dart';
import '../../data/models/register_wallet_request.dart';

class RegisterWalletPage extends StatefulWidget {
  const RegisterWalletPage({super.key});

  @override
  State<RegisterWalletPage> createState() => _RegisterWalletPageState();
}

class _RegisterWalletPageState extends State<RegisterWalletPage> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();

  List<AccountItem> _cuentas = [];
  AccountItem? _cuentaSeleccionada;
  bool _cargando = true;
  String _errorCarga = '';
  bool _procesando = false;
  int _usuarioID = 0;
  String _identificacion = '';

  http.Client get _httpClient {
    final ioc = HttpClient();
    ioc.badCertificateCallback = (cert, host, port) => true;
    return IOClient(ioc);
  }

  @override
  void initState() {
    super.initState();
    _cargarCuentas();
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCuentas() async {
    setState(() {
      _cargando = true;
      _errorCarga = '';
    });

    try {
      final token = await _storage.read(key: 'access_token');
      final usuarioIdStr = await _storage.read(key: 'usuarioID');
      final identificacion = await _storage.read(key: 'identificacion');

      if (token == null || usuarioIdStr == null) {
        setState(() {
          _errorCarga = 'Sesión no válida. Por favor inicie sesión nuevamente.';
          _cargando = false;
        });
        return;
      }

      _usuarioID = int.tryParse(usuarioIdStr) ?? 0;
      _identificacion = identificacion ?? '';

      print('SESION: usuarioID=$_usuarioID | identificacion=$_identificacion');

      final client = _httpClient;
      final resp = await client.get(
        Uri.parse(
            'https://10.0.2.2:7191/core/accounts/cliente/$_usuarioID'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('CUENTAS RESPONSE [${resp.statusCode}]: ${resp.body}');

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        setState(() {
          _cuentas = data.map((e) => AccountItem.fromJson(e)).toList();
          _cargando = false;
        });
      } else {
        final data = jsonDecode(resp.body);
        setState(() {
          _errorCarga =
              data['descripcion'] ?? 'Error al obtener cuentas (${resp.statusCode})';
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorCarga = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _inscribir() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaSeleccionada == null) return;

    final confirm = await UIUtils.showConfirmDialog(
      context,
      'Confirmar inscripción',
      '¿Desea asociar el teléfono ${_telefonoCtrl.text} con la cuenta ${_cuentaSeleccionada!.numeroCuenta}?',
    );
    if (!confirm) return;

    setState(() => _procesando = true);

    try {
      final token = await _storage.read(key: 'access_token');

      final request = RegisterWalletRequest(
        identificacion: _identificacion,
        numeroCuenta: _cuentaSeleccionada!.numeroCuenta,
        telefono: _telefonoCtrl.text.trim(),
      );

      final bodyJson = jsonEncode(request.toJson());
      print('INSCRIBIR REQUEST: $bodyJson');

      final client = _httpClient;
      final resp = await client.post(
        Uri.parse('https://10.0.2.2:7154/pagomovil/inscribir'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: bodyJson,
      );

      print('INSCRIBIR RESPONSE [${resp.statusCode}]: ${resp.body}');
      final data = jsonDecode(resp.body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        _telefonoCtrl.clear();
        setState(() => _cuentaSeleccionada = null);
        if (mounted) {
          UIUtils.showMsg(context, 'Inscripción exitosa');
        }
      } else {
        final mensaje =
            data['descripcion'] ?? 'Error al procesar la inscripción';
        if (mounted) {
          UIUtils.showMsg(context, mensaje, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showMsg(context, 'Error de conexión: $e', isError: true);
      }
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorCarga.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorCarga, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cargarCuentas,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inscribirse en Pagos Móviles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Asocia tu número de teléfono y cuenta bancaria para usar el servicio.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Dropdown de cuentas
            if (_cuentas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: const [
                      Icon(Icons.info_outline, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No se encontraron cuentas disponibles.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              DropdownButtonFormField<AccountItem>(
                value: _cuentaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Cuenta bancaria',
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _cuentas
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${c.numeroCuenta}  —  ₡${c.saldo.toStringAsFixed(2)}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _cuentaSeleccionada = val),
                validator: (_) =>
                    _cuentaSeleccionada == null ? 'Seleccione una cuenta' : null,
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: 'Número de teléfono',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El número de teléfono es requerido';
                  }
                  final regex = RegExp(r'^(?:2|4|5|6|7|8)\d{7}$');
                  if (!regex.hasMatch(val.trim())) {
                    return 'Teléfono inválido (8 dígitos, inicia en 2,4,5,6,7 u 8)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _procesando ? null : _inscribir,
                  icon: _procesando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(
                    _procesando ? 'Procesando...' : 'Inscribirse',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
