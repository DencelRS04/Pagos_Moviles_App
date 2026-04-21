import 'package:flutter/material.dart';
import 'package:pagos_moviles_app/services/auth_service.dart';
import '../widgets/ui_utils.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/transfer/presentation/pages/transfer_page.dart';
import '../features/subscription/presentation/pages/register_wallet_page.dart';
import '../features/balance/presentation/pages/balance_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    HomePage(onTransferir: () => onTransferirTap()),
    const RegisterWalletPage(),
    const BalancePage(),
    const Center(child: Text("Historial de Movimientos")),
    const TransferPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
              // --- LOGO ARREGLADO CON ERROR BUILDER ---
              child: Image.asset(
                'assets/images/logo_cuc.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.account_balance,
                    color: colorPrimario,
                    size: 20,
                  );
                },
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
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05)),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: colorAcento.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.bold, // Un poco más grueso para que se lea mejor
              color: colorPrimario,
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
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.app_registration_outlined),
              selectedIcon: Icon(Icons.app_registration, color: colorAcento),
              label: 'Inscribir',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(
                Icons.account_balance_wallet,
                color: colorAcento,
              ),
              label: 'Saldo',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: colorAcento),
              label: 'Movimientos',
            ),
            NavigationDestination(
              icon: Icon(Icons.send_outlined),
              selectedIcon: Icon(Icons.send, color: colorAcento),
              label: 'Transferir',
            ),
          ],
        ),
      ),
    );
  }
}
