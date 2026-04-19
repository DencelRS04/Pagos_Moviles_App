import 'package:flutter/material.dart';
import 'package:pagos_moviles_app/services/auth_service.dart';
import '../widgets/ui_utils.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/transfer/presentation/pages/transfer_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Usamos late para poder pasar 'onTransferirTap' a HomePage
  late final List<Widget> _screens = [
    HomePage(onTransferir: () => onTransferirTap()),
    const Center(child: Text("Pantalla Inscribir/Desinscribir")),
    const Center(child: Text("Pantalla Ver Saldo")),
    const Center(child: Text("Pantalla ver movimientos")),
    const TransferPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Método para que desde el Inicio se pueda saltar al tab de Transferir
  void onTransferirTap() {
    setState(() {
      _selectedIndex = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    const colorPrimario = Color(0xFF003366);
    const colorAcento = Color(0xFFF57C00);

    return Scaffold(
      // 1. BARRA SUPERIOR ESTILIZADA
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
            onPressed: () async {
              bool confirm = await UIUtils.showConfirmDialog(
                context,
                "Cerrar Sesión",
                "¿Desea limpiar sus credenciales locales?",
              );
              if (confirm) {
                await AuthService().logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),

      // 2. CONTENIDO CON TRANSICIÓN SUAVE
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05)),
          child: _screens[_selectedIndex],
        ),
      ),

      // 3. BARRA INFERIOR ALINEADA Y COMPLETA
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: colorAcento.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colorPrimario,
              height: 1.1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 15,
          height: 80,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: colorAcento),
              label: 'Inicio\n ',
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
              label: 'Ver saldo\n ',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: colorAcento),
              label: 'ver\nmovimientos',
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
