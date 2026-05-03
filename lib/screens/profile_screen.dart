import 'package:flutter/material.dart';
import 'package:projeto_cm/screens/welcome_screen.dart';
import '../constants/colors.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 32),
          
          // Avatar e Nome
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: CERESColors.primaryDarkGreen,
                  child: Text('M', style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                const Text('Mariana', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                Text('mariana@plantteste.com', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Menu de Opções
          _buildMenuTile(Icons.eco, 'As minhas plantas', () {}),
          _buildMenuTile(Icons.settings, 'Configurações', () {}),
          _buildMenuTile(Icons.help_outline, 'Ajuda e Suporte', () {}),
          
          const Divider(height: 40),
          
          _buildMenuTile(Icons.logout, 'Sair da Conta', () {
              // volta para o inicio
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (Route<dynamic> route) => false, // apaga as screens anteriores
              );
            }, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : CERESColors.primaryDarkGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : CERESColors.primaryDarkGreen),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : CERESColors.textMain)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}