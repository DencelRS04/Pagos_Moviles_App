import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../widgets/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  final String? message; // Para el mensaje de "Por favor inicie sesión..."
  const LoginScreen({super.key, this.message});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- MANTENEMOS LA LÓGICA EXACTA (AM2) ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  // Dominio parametrizable (AM2)
  final String dominioRequerido = "cuc.cr";
  bool _recordarme = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosGuardados(); // Carga el correo si fue recordado

    // Si viene un mensaje por redirección, lo mostramos (AM2)
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UIUtils.showMsg(context, widget.message!, isError: true);
      });
    }
  }

  // Lee el correo si se marcó "Recordarme" anteriormente
  void _cargarDatosGuardados() async {
    String? emailGuardado = await _storage.read(key: 'remembered_email');
    if (emailGuardado != null) {
      setState(() {
        _emailController.text = emailGuardado;
        _recordarme = true;
      });
    }
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validación TAL CUAL: email con dominio y contraseña no vacía
    if (email.isEmpty ||
        !email.endsWith('@$dominioRequerido') ||
        password.isEmpty) {
      UIUtils.showMsg(
        context,
        "Usuario y/o contraseña incorrectos.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(email, password);
      if (result != null) {
        print("BITÁCORA: Login exitoso para $email");
        if (_recordarme) {
          await _storage.write(key: 'remembered_email', value: email);
        } else {
          await _storage.delete(key: 'remembered_email');
        }

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print("BITÁCORA: Login fallido para $email. Razón: $e");
      UIUtils.showMsg(context, e.toString(), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- COMIENZA LA MEJORA DE INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    // Definimos colores institucionales para consistencia visual (AM1)
    const colorPrimario = Color(0xFF003366); // Azul CUC
    const colorAcento = Color(0xFFF57C00); // Naranja para resaltar el botón

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Fondo Bonito: Imagen sutil con overlay azul
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/background_pattern.png',
                ), // Puedes agregar un patrón de fondo opcional
                fit: BoxFit.cover,
                opacity: 0.05, // Muy sutil
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorPrimario.withOpacity(0.9),
                  colorPrimario.withOpacity(0.95),
                ],
              ),
            ),
          ),

          // 2. Contenido Principal Centrado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- EL LOGO BONITO (AM2) ---
                  // Usamos Hero para una transición suave si lo usas en otra pantalla
                  Hero(
                    tag: 'logo_cuc',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo_cuc.png', // Tu logo descargado
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Pagos Móviles",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- CONTENEDOR FLOTANTE DEL FORMULARIO ---
                  Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Iniciar Sesión",
                            style: TextStyle(
                              color: colorPrimario,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),

                          // --- TEXTFIELDS ESTILIZADOS ---
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Correo (@$dominioRequerido)',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: colorPrimario,
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outlined,
                                color: colorPrimario,
                              ),
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // --- CHECKBOX OPTIMIZADO ---
                          CheckboxListTile(
                            title: const Text(
                              "Recordarme",
                              style: TextStyle(
                                color: colorPrimario,
                                fontSize: 14,
                              ),
                            ),
                            value: _recordarme,
                            onChanged: (val) =>
                                setState(() => _recordarme = val!),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: colorAcento,
                            dense: true,
                          ),
                          const SizedBox(height: 25),

                          // --- BOTÓN ACEPTAR RESALTADO Y BONITO ---
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: colorAcento,
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          colorAcento, // Naranja para resaltar
                                      foregroundColor: Colors.white,
                                      elevation: 6,
                                      shadowColor: colorAcento.withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      "ACEPTAR",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
