import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Variáveis para guardar o estado visual dos botões
  bool _notifications = true;
  bool _darkMode = false;

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
            activeColor: CERESColors.primaryDarkGreen, 
            value: _notifications, 
            onChanged: (val) {
              setState(() => _notifications = val); // Agora já liga e desliga!
            }
          ),
          SwitchListTile(
            title: const Text('Modo Escuro (Dark Mode)'), 
            activeColor: CERESColors.primaryDarkGreen, 
            value: _darkMode, 
            onChanged: (val) {
              setState(() => _darkMode = val);
              // Aviso para a apresentação:
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
              // Dá feedback visual em vez de não fazer nada
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrir formulário de edição...')));
            }
          ),
        ],
      ),
    );
  }
}