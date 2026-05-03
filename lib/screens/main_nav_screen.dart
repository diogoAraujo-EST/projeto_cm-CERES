import 'package:flutter/material.dart';
import 'package:projeto_cm/screens/profile_screen.dart';
import 'home_screen.dart';
import 'statistics_screen.dart';
import '../constants/colors.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  // Lista de ecrãs
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text("Página das Plantas (Em construção)")),
    const Center(child: Text("Calendário (Em construção)")),
    const StatisticsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nova Planta!!!')),
          );
        },
          backgroundColor: CERESColors.primaryDarkGreen,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28,),  
        ) : null,
      
      // Bottom Navigation Bar
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
          currentIndex: _selectedIndex,
          selectedItemColor: CERESColors.primaryDarkGreen,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          onTap: (index) => setState(() => _selectedIndex = index),
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