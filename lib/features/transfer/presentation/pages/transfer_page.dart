import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../../../widgets/ui_utils.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  final _telefonoOrigenCtrl = TextEditingController();
  final _telefonoDestinoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  String _nombreOrigen = '';
  bool _cargandoSesion = true;
  bool _procesando = false;

  http.Client get _httpClient {
    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosSesion();
  }

  @override
  void dispose() {
    _telefonoOrigenCtrl.dispose();
    _telefonoDestinoCtrl.dispose();
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosSesion() async {
    try {
      final nombreGuardado = await _storage.read(key: 'nombre_completo');
      setState(() {
        _nombreOrigen = nombreGuardado ?? '';
        _cargandoSesion = false;
      });
    } catch (e) {
      setState(() => _cargandoSesion = false);
    }
  }

  Future<void> _procesarTransferencia() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await UIUtils.showConfirmDialog(
      context,
      'Confirmar transferencia',
      '¿Desea transferir ₡${_montoCtrl.text} a ${_telefonoDestinoCtrl.text}?',
    );

    if (!confirm) return;

    setState(() => _procesando = true);

    try {
      final token = await _storage.read(key: 'access_token');

      final body = jsonEncode({
        'telefonoOrigen': _telefonoOrigenCtrl.text.trim(),
        'nombreOrigen': _nombreOrigen,
        'telefonoDestino': _telefonoDestinoCtrl.text.trim(),
        'monto': double.parse(_montoCtrl.text.trim()),
        'descripcion': _descripcionCtrl.text.trim(),
      });

      final client = _httpClient;
      final resp = await client.post(
        Uri.parse('https://10.0.2.2:7000/gateway/admin/transactions/route'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final data = jsonDecode(resp.body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        _telefonoOrigenCtrl.clear();
        _telefonoDestinoCtrl.clear();
        _montoCtrl.clear();
        _descripcionCtrl.clear();
        if (mounted) {
          UIUtils.showMsg(context, 'Transferencia realizada exitosamente');
        }
      } else {
        final mensaje = data['descripcion'] ?? 'Error al procesar transferencia';
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
    if (_cargandoSesion) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Realizar Transferencia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 20),

            // Teléfono origen (ahora editable)
            TextFormField(
              controller: _telefonoOrigenCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: 'Teléfono origen',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'El teléfono origen es requerido';
                }
                final regex = RegExp(r'^(?:2|4|5|6|7|8)\d{7}$');
                if (!regex.hasMatch(val.trim())) {
                  return 'Teléfono inválido (8 dígitos, inicia en 2,4,5,6,7 u 8)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Nombre origen (solo lectura)
            TextFormField(
              initialValue: _nombreOrigen,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Nombre origen',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Teléfono destino
            TextFormField(
              controller: _telefonoDestinoCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: 'Teléfono destino',
                prefixIcon: const Icon(Icons.phone_forwarded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'El teléfono destino es requerido';
                }
                final regex = RegExp(r'^(?:2|4|5|6|7|8)\d{7}$');
                if (!regex.hasMatch(val.trim())) {
                  return 'Teléfono inválido (8 dígitos, inicia en 2,4,5,6,7 u 8)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Monto
            TextFormField(
              controller: _montoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto (₡)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'El monto es requerido';
                }
                final monto = double.tryParse(val.trim());
                if (monto == null || monto <= 0) {
                  return 'Ingrese un monto válido';
                }
                if (monto > 100000) {
                  return 'El monto no debe superar ₡100.000';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Descripción
            TextFormField(
              controller: _descripcionCtrl,
              maxLength: 25,
              decoration: InputDecoration(
                labelText: 'Descripción',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'La descripción es requerida';
                }
                if (val.trim().length > 25) {
                  return 'Máximo 25 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _procesarTransferencia,
                icon: _procesando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _procesando ? 'Procesando...' : 'Enviar Transferencia',
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
        ),
      ),
    );
  }
}