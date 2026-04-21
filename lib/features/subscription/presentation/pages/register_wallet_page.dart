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
  bool _modoInscripcion = true;
  String _identificacion = '';
  String _clienteId = '';

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
      final clienteId = await _storage.read(key: 'clienteId');

      if (token == null || usuarioIdStr == null) {
        setState(() {
          _errorCarga = 'Sesión no válida. Por favor inicie sesión nuevamente.';
          _cargando = false;
        });
        return;
      }

      _identificacion = identificacion ?? '';
      _clienteId = clienteId ?? '';

      final client = _httpClient;
      final resp = await client.get(
        Uri.parse(
            'https://10.0.2.2:7191/core/accounts/cliente/$_clienteId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );


      if (resp.statusCode == 200) {
        if (resp.body.trim().isEmpty) {
          setState(() {
            _cuentas = [];
            _cargando = false;
          });
          return;
        }
        final body = jsonDecode(resp.body);
        final List<dynamic> datos = body is Map ? (body['datos'] ?? []) : body;
        setState(() {
          _cuentas = datos.map((e) => AccountItem.fromJson(e)).toList();
          _cargando = false;
        });
      } else {
        String mensajeError = 'Error al obtener cuentas (${resp.statusCode})';
        if (resp.body.trim().isNotEmpty) {
          try {
            final data = jsonDecode(resp.body);
            mensajeError = data['descripcion'] ?? mensajeError;
          } catch (_) {
            mensajeError = 'Error ${resp.statusCode}: ${resp.body}';
          }
        }
        setState(() {
          _errorCarga = mensajeError;
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

  Future<void> _procesar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaSeleccionada == null) return;

    final accion = _modoInscripcion ? 'inscripción' : 'desinscripción';
    final verbo = _modoInscripcion ? 'asociar' : 'desasociar';

    final confirm = await UIUtils.showConfirmDialog(
      context,
      'Confirmar $accion',
      '¿Desea $verbo el teléfono ${_telefonoCtrl.text} con la cuenta ${_cuentaSeleccionada!.numeroCuenta}?',
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
      final client = _httpClient;

      final url = _modoInscripcion
          ? 'https://10.0.2.2:7154/pagomovil/inscribir'
          : 'https://10.0.2.2:7000/gateway/admin/core/accounts/unsubscribe';

      final resp = await client.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: bodyJson,
      );

      Map<String, dynamic> data = {};
      if (resp.body.trim().isNotEmpty) {
        try {
          data = jsonDecode(resp.body);
        } catch (_) {}
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        _telefonoCtrl.clear();
        setState(() => _cuentaSeleccionada = null);
        if (mounted) {
          UIUtils.showMsg(
            context,
            _modoInscripcion ? 'Inscripción exitosa' : 'Desinscripción exitosa',
          );
        }
      } else {
        final mensaje =
            data['descripcion'] as String? ?? 'Error al procesar la $accion (${resp.statusCode})';
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
              'Pagos Móviles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle Inscribir / Desinscribir
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Inscribirse'),
                  icon: Icon(Icons.person_add),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Desinscribirse'),
                  icon: Icon(Icons.person_remove),
                ),
              ],
              selected: {_modoInscripcion},
              onSelectionChanged: (sel) {
                setState(() {
                  _modoInscripcion = sel.first;
                  _telefonoCtrl.clear();
                  _cuentaSeleccionada = null;
                });
              },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : const Color(0xFF003366),
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? const Color(0xFF003366)
                      : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _modoInscripcion
                  ? 'Asocia tu número de teléfono y cuenta bancaria para usar el servicio.'
                  : 'Desasocia tu número de teléfono y cuenta bancaria del servicio.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                initialValue: _cuentaSeleccionada,
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
                  onPressed: _procesando ? null : _procesar,
                  icon: _procesando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _modoInscripcion
                              ? Icons.person_add
                              : Icons.person_remove,
                        ),
                  label: Text(
                    _procesando
                        ? 'Procesando...'
                        : (_modoInscripcion ? 'Inscribirse' : 'Desinscribirse'),
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
