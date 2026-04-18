import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AuthGuard(child: MainLayout()),
      },
      initialRoute: '/login',
    );
  }
}

// El "Guard" que protege las pantallas (AM2)
class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  Future<bool> _checkAuth() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'access_token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return child;
        } else {
          // Redirección con mensaje exacto (AM2)
          // En tu AuthGuard
          return const LoginScreen(
            message: "Por favor inicie sesión para utilizar el sistema",
          );
        }
      },
    );
  }
}
