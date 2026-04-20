import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../widgets/ui_utils.dart';

class LoginScreen extends StatefulWidget {
  final String? message;
  const LoginScreen({super.key, this.message});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  final String dominioRequerido = "cuc.cr";
  bool _recordarme = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosGuardados();

    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UIUtils.showMsg(context, widget.message!, isError: true);
      });
    }
  }

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
        if (_recordarme) {
          await _storage.write(key: 'remembered_email', value: email);
        } else {
          await _storage.delete(key: 'remembered_email');
        }
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      UIUtils.showMsg(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimario = Color(0xFF003366);
    const colorAcento = Color(0xFFF57C00);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // FONDO: Gradiente azul sólido
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colorPrimario, colorPrimario.withOpacity(0.8)],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO ARREGLADO ---
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
                        'assets/images/logo_cuc.png',
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                        // Si la imagen falla, muestra este icono
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.account_balance,
                            size: 80,
                            color: colorPrimario,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "DAYJA BANK",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // TARJETA DEL FORMULARIO
                  Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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

                          // EMAIL
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
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
                            ),
                          ),
                          const SizedBox(height: 18),

                          // PASSWORD
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
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
                            ),
                          ),

                          // RECORDARME
                          CheckboxListTile(
                            title: const Text(
                              "Recordarme",
                              style: TextStyle(fontSize: 14),
                            ),
                            value: _recordarme,
                            onChanged: (val) =>
                                setState(() => _recordarme = val!),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: colorAcento,
                          ),
                          const SizedBox(height: 20),

                          // BOTÓN ACEPTAR
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
                                      backgroundColor: colorAcento,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Text(
                                      "ACEPTAR",
                                      style: TextStyle(
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
