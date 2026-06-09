import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estados locais dos botões (switches)
  bool _notifications = false;
  bool _darkMode = false;
  
  // Instância do nosso serviço que fala com o sistema de notificações do telemóvel
  final NotificationService _notificationService = NotificationService();
  
  // Usamos "late" porque não conseguimos dar um valor a esta variável no momento exato 
  // em que o ecrã é desenhado (precisamos de "esperar" pelo telemóvel no initState).
  late SharedPreferences _prefs; // Instância da persistência local

  @override
  void initState() {
    super.initState();
    // Assim que a pessoa abre o ecrã de configurações, pedimos autorização nativa
    // (Aquele pop-up do telemóvel a perguntar "A app CERES quer enviar-te notificações. Permitir?")
    _notificationService.requestPermissions();
    // Assim que o ecrã abre, vamos ao disco do telemóvel ver como estavam os botões da última vez
    _loadPreferences(); 
  }

  // --- PERSISTÊNCIA LOCAL (SHARED PREFERENCES) ---
  // O SharedPreferences é como uma pequena gaveta local no telemóvel onde podemos 
  // guardar definições simples sem usar internet nem bases de dados complexas.
  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      // Tenta ler o valor da gaveta. 
      // Se não existir nada lá dentro (ex: primeira vez que a pessoa abre a app), assume 'false' (?? false).
      _notifications = _prefs.getBool('notifications_enabled') ?? false;
      _darkMode = _prefs.getBool('dark_mode_enabled') ?? false;
    });
  }

  // Guarda a preferência de notificações
  Future<void> _saveNotificationPreference(bool value) async {
    setState(() => _notifications = value); // Atualiza a UI visualmente na hora
    await _prefs.setBool('notifications_enabled', value); // Grava a escolha na memória física do telemóvel
  }

  // Guarda a preferência do Modo Escuro
  Future<void> _saveDarkModePreference(bool value) async {
    setState(() => _darkMode = value);
    await _prefs.setBool('dark_mode_enabled', value); // Grava no telemóvel
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
          
          // --- TOGGLE NOTIFICAÇÕES ---
          SwitchListTile(
            title: const Text('Notificações de Rega'), 
            subtitle: const Text('Ativa para testar uma notificação agora!'),
            activeThumbColor: CERESColors.primaryDarkGreen, 
            value: _notifications, 
            onChanged: (val) {
              _saveNotificationPreference(val); // Grava localmente em vez de usar apenas setState
              
              // Se a pessoa ligou o botão, dispara a notificação de teste!
              if (val) {
                _notificationService.showInstantNotification(
                  title: '🌿 Hora de Regar!',
                  body: 'A tua Monstera está com sede. Vai ver as tuas plantas!',
                );
              }
            }
          ),
          
          // --- TOGGLE MODO ESCURO ---
          SwitchListTile(
            title: const Text('Modo Escuro (Dark Mode)'), 
            activeThumbColor: CERESColors.primaryDarkGreen, 
            value: _darkMode, 
            onChanged: (val) {
              _saveDarkModePreference(val); // Grava localmente
              
              // Truque de UI/UX (Graceful degradation): Mostra a opção (gera curiosidade), 
              // mas avisa o utilizador de forma simpática que a funcionalidade ainda está no forno.
              if (val) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tema escuro não desenvolvido nesta versão. Fica atento às próximas atualizações!')));
              }
            }
          ),
          
          const Divider(height: 40),
          
          // --- EDITAR PERFIL ---
          ListTile(
            title: const Text('Editar Perfil'), 
            trailing: const Icon(Icons.chevron_right), 
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