import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onTransferir;
  const HomePage({super.key, this.onTransferir});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final _storage = const FlutterSecureStorage();

  String _nombreUsuario = '';
  String _telefono = '';
  String _fechaIngreso = '';
  List<dynamic> _cuentas = [];
  bool _cargando = true;
  String _error = '';

  http.Client get _httpClient {
    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  @override
  void initState() {
    super.initState();
    _fechaIngreso = _formatearFecha(DateTime.now());
    _cargarDatos();
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _cargarDatos() async {
  try {
    final token = await _storage.read(key: 'access_token');
    final usuarioIdStr = await _storage.read(key: 'usuarioID');
    final nombreGuardado = await _storage.read(key: 'nombre_completo');

    if (token == null || usuarioIdStr == null) {
      setState(() {
        _error = 'Sesión no válida';
        _cargando = false;
      });
      return;
    }

    // El nombre viene guardado desde el login
    _nombreUsuario = nombreGuardado ?? 'Usuario';

    setState(() {
      _cuentas = [];
      _cargando = false;
    });
  } catch (e) {
    setState(() {
      _error = 'Error al cargar datos: $e';
      _cargando = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = '';
                });
                _cargarDatos();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _cargando = true);
        await _cargarDatos();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta bienvenida
            Card(
              color: const Color(0xFF003366),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child:
                          Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bienvenido,',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            _nombreUsuario,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _fechaIngreso,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botón transferencia
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onTransferir?.call();
                },
                icon: const Icon(Icons.swap_horiz),
                label: const Text(
                  'Realizar Transferencia',
                  style: TextStyle(fontSize: 16),
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

            const SizedBox(height: 24),

            // Cuentas asociadas
            const Text(
              'Cuentas asociadas a Pagos Móviles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 12),

            _cuentas.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: const [
                          Icon(Icons.info_outline,
                              size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No tienes cuentas asociadas a Pagos Móviles.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cuentas.length,
                    itemBuilder: (context, index) {
                      final cuenta = _cuentas[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF003366),
                            child: Icon(Icons.phone_android,
                                color: Colors.white),
                          ),
                          title: Text(
                            'Tel: ${cuenta['telefono'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Cuenta: ${cuenta['numeroCuenta'] ?? 'N/A'}',
                          ),
                          trailing: const Icon(Icons.check_circle,
                              color: Colors.green),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}