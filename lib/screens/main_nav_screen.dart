import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class MainNavScreen extends StatelessWidget {

  final StatefulNavigationShell navigationShell;

  const MainNavScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: navigationShell,
      
      floatingActionButton: navigationShell.currentIndex == 0 
        ? FloatingActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nova Planta!!!')),
              );
            },
            backgroundColor: CERESColors.primaryDarkGreen,
            shape: const CircleBorder(),
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white, size: 28),  
          ) 
        : null,
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: navigationShell.currentIndex,
          selectedItemColor: CERESColors.primaryDarkGreen,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          onTap: (index) {
            navigationShell.goBranch(
              index,
              // se clicares na pagina e já la tiveres, faz scroll para o topo, se clicares numa pagina diferente, vai para a pagina
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Início'),
            BottomNavigationBarItem(icon: Icon(Icons.eco_outlined), label: 'Plantas'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Calendário'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Estatísticas'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}