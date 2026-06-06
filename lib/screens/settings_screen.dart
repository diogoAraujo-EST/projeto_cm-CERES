import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = false; // Começa desligado até darmos permissão
  bool _darkMode = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Pede permissão para enviar notificações mal o ecrã abre
    _notificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
        title: const Text('Configurações', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SwitchListTile(
            title: const Text('Notificações de Rega'), 
            subtitle: const Text('Ativa para testar uma notificação agora!'),
            activeColor: CERESColors.primaryDarkGreen, 
            value: _notifications, 
            onChanged: (val) {
              setState(() => _notifications = val);
              
              // SE O UTILIZADOR LIGAR O BOTÃO, DISPARA A NOTIFICAÇÃO!
              if (val) {
                _notificationService.showInstantNotification(
                  title: '🌿 Hora de Regar!',
                  body: 'A tua Monstera está com sede. Vai ver as tuas plantas!',
                );
              }
            }
          ),
          SwitchListTile(
            title: const Text('Modo Escuro (Dark Mode)'), 
            activeColor: CERESColors.primaryDarkGreen, 
            value: _darkMode, 
            onChanged: (val) {
              setState(() => _darkMode = val);
              if (val) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tema escuro será aplicado na versão final.')));
              }
            }
          ),
          const Divider(height: 40),
          ListTile(
            title: const Text('Editar Perfil'), 
            trailing: const Icon(Icons.chevron_right), 
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrir formulário de edição...')));
            }
          ),
        ],
      ),
    );
  }
}