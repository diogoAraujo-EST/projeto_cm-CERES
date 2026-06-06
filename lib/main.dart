import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';


// ecrãs da aplicaçãp
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
import 'constants/colors.dart';
import 'services/notification_service.dart';
import 'models/user_plant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print("Firebase inicializado com sucesso!");
    
    // Inicializa o serviço de notificações!
    await NotificationService().init();
    
  } catch (e) {
    print("Erro na inicialização: $e");
  }

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final loggingIn = state.matchedLocation == '/login' || 
                      state.matchedLocation == '/register' || 
                      state.matchedLocation == '/';

    // Se não estiver logado e tentar aceder a um ecrã privado, vai para o Welcome
    if (user == null && !loggingIn) {
      return '/';
    }
    // Se estiver logado e tentar ir ao Welcome/Login/Register, vai para a Home
    if (user != null && loggingIn) {
      return '/home';
    }
    return null;
  },
  routes: [
    // 1. Boas-Vindas
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavScreen(navigationShell: navigationShell);
      },
      branches: [
        // Separador 0: Início
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())],
        ),
        // Separador 1: Plantas POR FAZER - AINDA NÃO TEMOS O ECRÃ PRONTO, POR ISSO VAMOS USAR UM PLACEHOLDER
        StatefulShellBranch(
          routes: [GoRoute(path: '/plants', builder: (context, state) => const PlantsScreen())],
        ),
        // Separador 2: Calendaario
        StatefulShellBranch(
          routes: [GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen())],
        ),
        // Separador 3: Estatísticas POR FAZER - ECRÃ EXISTE, MAS NÃO TEM "FUNCIONALIZADES"
        StatefulShellBranch(
          routes: [GoRoute(path: '/statistics', builder: (context, state) => const StatisticsScreen())],
        ),
        // Separador 4: Perfil
        StatefulShellBranch(
          routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
        ),
      ],
    ),

// detalhes de planta
   GoRoute(
      path: '/plant-details',
      builder: (context, state) {
        final plant = state.extra as UserPlant; // Agora passa o objeto inteiro!
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
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router( 
      title: 'CERES',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: CERESColors.primaryDarkGreen,
      ),
      routerConfig: _router, 
    );
  }
}