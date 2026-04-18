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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo alusivo (AM2)
            const Icon(
              Icons.account_balance,
              size: 100,
              color: Color(0xFF003366),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo (@$dominioRequerido)',
              ),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            CheckboxListTile(
              title: const Text("Recordarme"),
              value: _recordarme,
              onChanged: (val) => setState(() => _recordarme = val!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("ACEPTAR"),
                  ),
          ],
        ),
      ),
    );
  }
}
