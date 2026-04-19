import 'package:flutter/material.dart';
import 'package:pagos_moviles_app/services/auth_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Lista de pantallas para navegar
  final List<Widget> _screens = [
    const Center(child: Text("Pantalla de Inicio")),
    const Center(child: Text("Pantalla Inscribir/Desinscribir")),
    const Center(child: Text("Pantalla Ver Saldo")),
    const Center(child: Text("Pantalla ver movimientos")),
    const Center(child: Text("Pantalla realizar transferencia")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimario = Color(0xFF003366); // Azul CUC
    const colorAcento = Color(0xFFF57C00); // Naranja

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorPrimario,
        elevation: 4,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_cuc.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        title: const Text(
          "DAYJA BANK",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              AuthService().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05)),
        child: _screens[_selectedIndex],
      ),

      // BARRA INFERIOR CON ALINEACIÓN FORZADA Y NOMBRES EXACTOS
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: colorAcento.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colorPrimario,
              height: 1.1, // Ajusta el espacio entre las dos líneas
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 15,
          height: 80, // Altura fija para que no se mueva
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: colorAcento),
              label: 'Inicio\n ', // Agregamos un espacio abajo
            ),
            NavigationDestination(
              icon: Icon(Icons.app_registration_outlined),
              selectedIcon: Icon(Icons.app_registration, color: colorAcento),
              label: 'Inscribir/\nDesinscribir',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(
                Icons.account_balance_wallet,
                color: colorAcento,
              ),
              label: 'Ver saldo\n ', // Agregamos un espacio abajo
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: colorAcento),
              label: 'ver\nmovimientos', // Forzamos 2 líneas para alinear
            ),
            NavigationDestination(
              icon: Icon(Icons.send_outlined),
              selectedIcon: Icon(Icons.send, color: colorAcento),
              label: 'realizar\ntransferencia',
            ),
          ],
        ),
      ),
    );
  }
}
