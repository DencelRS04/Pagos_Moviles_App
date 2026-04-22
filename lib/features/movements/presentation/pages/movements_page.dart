import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pagos_moviles_app/features/movements/data/models/movement_item.dart';


class MovementsPage extends StatefulWidget {
  const MovementsPage({super.key});

  @override
  State<MovementsPage> createState() => _MovementsPageState();
}

class _MovementsPageState extends State<MovementsPage> {
  final _telefonoCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  List<MovementItem> _movimientos = [];
  Map<String, dynamic>? _afiliacion;
  bool _cargando = false;
  String _error = '';
  bool _consultado = false;

  final _regexTelefono = RegExp(r'^(?:2|4|5|6|7|8)\d{7}$');

  http.Client get _httpClient {
    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  // ✅ initState DENTRO de la clase
  @override
  void initState() {
    super.initState();
    _cargarTelefonoSesion();
  }

  // ✅ _cargarTelefonoSesion DENTRO de la clase
  Future<void> _cargarTelefonoSesion() async {
    final telefono = await _storage.read(key: 'telefono');
    if (telefono != null && telefono.isNotEmpty) {
      setState(() {
        _telefonoCtrl.text = telefono;
      });
    }
  }

  Future<void> _consultarMovimientos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = '';
      _consultado = false;
      _movimientos = [];
      _afiliacion = null;
    });

    final telefono = _telefonoCtrl.text.trim();

    try {
      final token = await _storage.read(key: 'access_token');
      final telefonoSesion = await _storage.read(key: 'telefono'); // ← Lee el teléfono del usuario
     // ← Validación: el teléfono ingresado debe ser el del usuario logueado
        if (telefonoSesion != null &&
            telefonoSesion.isNotEmpty &&
            telefono != telefonoSesion) {
          setState(() {
            _error = 'Este número no está registrado a su nombre.';
            _consultado = true;
            _cargando = false;
          });
          return;
        }

      final client = _httpClient;
      final resp = await client.get(
        Uri.parse('https://10.0.2.2:7000/gateway/admin/accounts/transactions/$telefono'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(resp.body);

     if (resp.statusCode == 200) {
  final datos = data['datos'];
  final afiliacion = datos['afiliacion'];
  final lista = datos['movimientos'] as List<dynamic>;

  // Leer el teléfono del usuario logueado desde storage
  final telefonoSesion = await _storage.read(key: 'telefono');

  // Validar que el teléfono consultado pertenece al usuario logueado
  if (telefonoSesion != null &&
      telefonoSesion.isNotEmpty &&
      afiliacion['telefono']?.toString() != telefonoSesion) {
    setState(() {
      _error = 'Este número no está registrado a su nombre.';
      _consultado = true;
    });
    return;
  }

  setState(() {
    _afiliacion = afiliacion;
    _movimientos = lista.map((e) => MovementItem.fromJson(e)).toList();
    _consultado = true;
  });
}else {
        setState(() {
          _error = data['descripcion'] ?? 'No se pudieron obtener los movimientos.';
          _consultado = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _consultado = true;
      });
    } finally {
      setState(() => _cargando = false);
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}  '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  String _formatearMonto(double monto) {
    return '₡${monto.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }

  IconData _iconMovimiento(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('debito') || t.contains('débito') || t.contains('retiro')) {
      return Icons.arrow_upward;
    }
    if (t.contains('credito') || t.contains('crédito') || t.contains('deposito')) {
      return Icons.arrow_downward;
    }
    return Icons.swap_horiz;
  }

  Color _colorMovimiento(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('debito') || t.contains('débito') || t.contains('retiro')) {
      return Colors.red;
    }
    if (t.contains('credito') || t.contains('crédito') || t.contains('deposito')) {
      return Colors.green;
    }
    return Colors.blueGrey;
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Últimos Movimientos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Consulte los últimos 5 movimientos de una cuenta',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 8,
                  decoration: InputDecoration(
                    labelText: 'Número de teléfono',
                    hintText: 'Ej: 88887777',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El teléfono es requerido.';
                    }
                    if (!_regexTelefono.hasMatch(v.trim())) {
                      return 'Teléfono inválido. Debe tener 8 dígitos e iniciar con 2, 4, 5, 6, 7 u 8.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _consultarMovimientos,
                    icon: _cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_cargando ? 'Consultando...' : 'Consultar movimientos'),
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

          const SizedBox(height: 24),

          if (_consultado) ...[
            if (_error.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_afiliacion != null)
                Card(
                  color: const Color(0xFF003366),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.phone_android, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tel: ${_afiliacion!['telefono'] ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Cuenta: ${_afiliacion!['numeroCuenta'] ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              if (_movimientos.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No hay movimientos registrados.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _movimientos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final mov = _movimientos[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _colorMovimiento(mov.tipoMovimiento).withOpacity(0.1),
                          child: Icon(
                            _iconMovimiento(mov.tipoMovimiento),
                            color: _colorMovimiento(mov.tipoMovimiento),
                          ),
                        ),
                        title: Text(
                          mov.tipoMovimiento,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_formatearFecha(mov.fecha)),
                        trailing: Text(
                          _formatearMonto(mov.monto),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _colorMovimiento(mov.tipoMovimiento),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ],
      ),
    );
  }
}