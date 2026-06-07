import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../services/notification_service.dart';

// É um StatefulWidget porque temos aqueles botões de "ligar/desligar" (switches)
// e precisamos de atualizar o ecrã instantaneamente quando o utilizador toca neles.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Variáveis que controlam os "switches" (botões de alternar)
  bool _notifications = false; // Começa desligado até o utilizador darmos permissão
  bool _darkMode = false; // (Ainda não implementado, mas já tem a variável pronta para o futuro!)
  
  // Instância do nosso serviço que fala com o sistema de notificações do telemóvel
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Assim que a pessoa abre o ecrã de configurações, pedimos autorização nativa
    // (Aquele pop-up do telemóvel a perguntar "A app CERES quer enviar-te notificações. Permitir?")
    _notificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // Cabeçalho básico
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // GoRouter context.pop() volta ao menu Perfil de onde viemos
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
        title: const Text('Configurações', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          
          // --- BOTÃO DE NOTIFICAÇÕES ---
          // O SwitchListTile é fantástico porque combina o texto (title), a explicação (subtitle)
          // e o botão de ligar/desligar (switch) tudo numa só linha organizada.
          SwitchListTile(
            title: const Text('Notificações de Rega'), 
            subtitle: const Text('Ativa para testar uma notificação agora!'),
            activeColor: CERESColors.primaryDarkGreen, 
            value: _notifications, 
            
            // O que acontece quando o utilizador toca no botão?
            onChanged: (val) {
              // 1. Muda a bolinha para a direita (verde)
              setState(() => _notifications = val);
              
              // 2. SE O UTILIZADOR LIGOU O BOTÃO (val == true)...
              // Aproveitamos para fazer uma demonstração ao vivo de como as notificações funcionam!
              if (val) {
                _notificationService.showInstantNotification(
                  title: '🌿 Hora de Regar!',
                  body: 'A tua Monstera está com sede. Vai ver as tuas plantas!',
                );
              }
            }
          ),
          
          const Divider(height: 40), // Linha separadora elegante
          
          // --- LINK PARA EDITAR O PERFIL ---
          ListTile(
            title: const Text('Editar Perfil'), 
            trailing: const Icon(Icons.chevron_right), // Setinha à direita
            onTap: () {
              // Salta para a página de edição de nome/password!
              context.push('/edit-profile');
            }
          ),
        ],
      ),
    );
  }
}