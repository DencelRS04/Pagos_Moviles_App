import 'package:flutter/material.dart';
import '../widgets/ui_utils.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Estas son las 5 áreas de contenido que pide tu documento
  final List<Widget> _screens = [
    const Center(child: Text("Pantalla de Inicio")),
    const Center(child: Text("Inscribir / Desinscribir")),
    const Center(child: Text("Saldo Actual")),
    const Center(child: Text("Historial de Movimientos")),
    const Center(child: Text("Formulario de Transferencia")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior con logo/título (Requerimiento AM1)
      appBar: AppBar(
        title: const Text("CUC Pagos Móviles"),
        backgroundColor: const Color(0xFF003366), // Azul institucional CUC
        leading: const Icon(
          Icons.account_balance,
          color: Color.fromARGB(255, 255, 255, 255),
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
                // Aquí limpiarás el secure storage en el siguiente paso
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),

      // Área de contenido dinámico
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),

      // Bottom Tab con todas las opciones solicitadas
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Permite más de 3 iconos
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
