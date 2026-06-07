import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// ecrãs da aplicação
import 'screens/calendar_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/plant_details_screen.dart';
import 'screens/add_plant_screen.dart' ;
import 'screens/plants_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'constants/colors.dart';
import 'services/notification_service.dart';
import 'models/user_plant.dart';

void main() async {
  // Isto é super importante! Como vamos falar com "o exterior" (Firebase e o sistema 
  // do telemóvel para as notificações) ANTES de a app desenhar o primeiro ecrã, 
  // temos de avisar o Flutter para ele preparar as ligações ao sistema operativo.
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Acorda o Firebase
    await Firebase.initializeApp();
    print("Firebase inicializado com sucesso!");
    
    // Inicializa o serviço de notificações (Pede permissões e prepara a app para receber alertas)
    await NotificationService().init();
    
  } catch (e) {
    print("Erro na inicialização: $e");
  }

  // Arranca o barco!
  runApp(const MyApp());
}

// --- O NOSSO MAPA DE NAVEGAÇÃO (GoRouter) ---
final GoRouter _router = GoRouter(
  initialLocation: '/', // A app começa sempre por tentar abrir a raiz (WelcomeScreen)
  
  // O "Segurança à Porta" da app. Ele analisa TODAS as mudanças de ecrã antes de elas acontecerem.
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    // Verifica se o destino do utilizador é um daqueles ecrãs públicos que não precisam de conta
    final loggingIn = state.matchedLocation == '/login' || 
                      state.matchedLocation == '/register' || 
                      state.matchedLocation == '/';

    // Se a pessoa NÃO tem o login feito e está a tentar forçar a entrada noutro ecrã (ex: /home)...
    // O segurança manda-a de volta para a rua (WelcomeScreen).
    if (user == null && !loggingIn) {
      return '/';
    }
    
    // Por outro lado, se ela JÁ tem conta e abre a app, não queremos chateá-la com o ecrã de 
    // Boas-Vindas outra vez. O segurança manda-a diretamente para dentro (Home).
    if (user != null && loggingIn) {
      return '/home';
    }
    
    // Se estiver tudo bem, retorna null (significa "Podes prosseguir viagem, está tudo ok").
    return null;
  },
  
  routes: [
    // 1. Ecrã de Boas-Vindas (A rua)
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),

    // --- A MAGIA DA BARRA INFERIOR ---
    // O StatefulShellRoute é o que permite ter uma barra de navegação sempre presente no fundo do ecrã,
    // e o "Stateful" significa que cada tab (Separador) tem memória e não faz refresh quando voltamos a ele.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Envolve as tabs todas na nossa "moldura" principal
        return MainNavScreen(navigationShell: navigationShell);
      },
      branches: [
        // Separador 0: Início
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())],
        ),
        // Separador 1: Plantas 
        StatefulShellBranch(
          routes: [GoRoute(path: '/plants', builder: (context, state) => const PlantsScreen())],
        ),
        // Separador 2: Calendário
        StatefulShellBranch(
          routes: [GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen())],
        ),
        // Separador 3: Estatísticas
        StatefulShellBranch(
          routes: [GoRoute(path: '/statistics', builder: (context, state) => const StatisticsScreen())],
        ),
        // Separador 4: Perfil
        StatefulShellBranch(
          routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
        ),
      ],
    ),

    // --- ROTAS SECUNDÁRIAS (Abrem "por cima" da barra de navegação) ---
    // Detalhes da planta
    GoRoute(
      path: '/plant-details',
      builder: (context, state) {
        // Truque de performance incrível: A página anterior envia a planta inteira na "mochila" (extra).
        // Assim, o ecrã de detalhes já tem a foto, nome, etc., e não gasta dados móveis a ir buscar ao Firebase outra vez.
        final plant = state.extra as UserPlant; 
        return PlantDetailsScreen(plant: plant);
      },
    ),

    GoRoute(
      path: '/add-plant',
      builder: (context, state) => const AddPlantScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);

// O Widget Base
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos MaterialApp.router porque estamos a usar o sistema de rotas avançado do GoRouter
    return MaterialApp.router( 
      title: 'CERES',
      debugShowCheckedModeBanner: false, // Tira aquela fita vermelha chata de "DEBUG" no canto do ecrã
      
      // O TEMA GLOBAL DA APP
      // Ao configurarmos isto aqui, não precisamos de pintar os cursores e as caixas de texto 
      // de verde uma a uma ao longo da app inteira. O Flutter faz isso por nós!
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: CERESColors.primaryDarkGreen,
          colorScheme: ColorScheme.fromSeed(
          seedColor: CERESColors.primaryDarkGreen,
          primary: CERESColors.primaryDarkGreen,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: CERESColors.primaryDarkGreen, // O tracinho a piscar quando escrevemos
          selectionColor: CERESColors.primaryDarkGreen.withValues(alpha: 0.3), // Fundo da seleção (verde clarinho) quando sublinhamos texto
          selectionHandleColor: CERESColors.primaryDarkGreen, // As "gotas" de arrastar para selecionar texto
        ),
      ),
      
      routerConfig: _router, // Liga a app ao nosso mapa de rotas lá de cima
    );
  }
}