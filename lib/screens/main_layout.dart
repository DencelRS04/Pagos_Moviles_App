import 'package:flutter/material.dart';
import '../widgets/ui_utils.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/transfer/presentation/pages/transfer_page.dart';
import '../features/subscription/presentation/pages/register_wallet_page.dart';

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
    const Center(child: Text("Saldo Actual")),
    const Center(child: Text("Historial de Movimientos")),
    const TransferPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Método público para que HomePage pueda navegar al tab de transferencias
  void onTransferirTap() {
    setState(() {
      _selectedIndex = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CUC Pagos Móviles"),
        backgroundColor: const Color(0xFF003366),
        leading: const Icon(
          Icons.account_balance,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              bool confirm = await UIUtils.showConfirmDialog(
                context,
                "Cerrar Sesión",
                "¿Desea limpiar sus credenciales locales?",
              );
              if (confirm) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF003366),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Inscribir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Saldo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Movimientos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Transferir',
          ),
        ],
      ),
    );
  }
}