import 'package:flutter/material.dart';
import 'package:projeto_cm/screens/Welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Perfil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          
          // Avatar e Nome Hardcoded
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green, // Cor básica
                  child: Text(
                    'M',
                    style: TextStyle(fontSize: 30, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Mariana',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'marianateste@plantas.com',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          const ListTile(
            leading: Icon(Icons.eco, color: Colors.green),
            title: Text('As minhas plantas'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.settings, color: Colors.green),
            title: Text('Configurações'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          const ListTile(
            leading: Icon(Icons.help_outline, color: Colors.green),
            title: Text('Ajuda e Suporte'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          
          const SizedBox(height: 30),
          
          //Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
            onTap: () {
              // Apaga o histórico todo e volta para o ecrã de início de sessão
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (Route<dynamic> route) => false, // O 'false' destrói as páginas anteriores
              );
            },
          ),
        ],
      ),
    );
  }
}