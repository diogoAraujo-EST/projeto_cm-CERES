import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importação do Firebase Auth
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;

    // Tratamento dinâmico para nome e email
    String displayName = 'Utilizador';
    String displayEmail = 'Sem e-mail registado';
    String avatarLetter = 'U';

    if (user != null) {
      if (user.isAnonymous) {
        displayName = 'Convidado';
        displayEmail = 'Acesso temporário';
        avatarLetter = 'C';
      } else {
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          displayName = user.displayName!;
          // Limita para segurança visual no perfil
          if (displayName.length > 20) {
            displayName = displayName.substring(0, 20);
          }
          avatarLetter = displayName[0].toUpperCase();
        }
        if (user.email != null && user.email!.isNotEmpty) {
          displayEmail = user.email!;
        }
      }
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text('Perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 32),
          
          // Avatar e Dados Dinâmicos
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: CERESColors.primaryDarkGreen,
                  child: user != null && user.isAnonymous
                      ? const Icon(Icons.person_outline, size: 48, color: Colors.white) // Ícone para convidado
                      : Text(avatarLetter, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                const SizedBox(height: 4),
                Text(displayEmail, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Menu de Opções
          _buildMenuTile(Icons.eco, 'As minhas plantas', () {
            context.go('/plants'); 
          }),
          _buildMenuTile(Icons.settings, 'Configurações', () {
            context.push('/settings'); 
          }),
          _buildMenuTile(Icons.help_outline, 'Ajuda e Suporte', () {
            context.push('/help'); 
          }),
          
          const Divider(height: 40),
          
          _buildMenuTile(Icons.logout, 'Sair da Conta', () async {
            await authService.signOut();
            if (context.mounted) {
              context.go('/');
            }
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
          color: isDestructive ? Colors.red.withValues(alpha: 0.1) : CERESColors.primaryDarkGreen.withValues(alpha: 0.1),
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