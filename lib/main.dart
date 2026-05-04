import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ecrãs da aplicaçãp
import 'screens/welcome_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/plant_details_screen.dart';
import 'constants/colors.dart';

void main() {
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/', // Começa no ecrã de Boas-vindas
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
          routes: [GoRoute(path: '/plants', builder: (context, state) => const Center(child: Text("Página das Plantas")))],
        ),
        // Separador 2: Calendário POR FAZER - AINDA NÃO TEMOS O ECRÃ PRONTO, POR ISSO VAMOS USAR UM PLACEHOLDER
        StatefulShellBranch(
          routes: [GoRoute(path: '/calendar', builder: (context, state) => const Center(child: Text("Calendário")))],
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

    // detalhes de planta - como ocupa o ecrã todo, fica fora do navBar
    GoRoute(
      path: '/plant-details',
      builder: (context, state) {
        // recebe os dados da planta 
        final extra = state.extra as Map<String, dynamic>;
        return PlantDetailsScreen(
          plantName: extra['name'],
          plantStatus: extra['status'],
          lastWatered: extra['lastWatered'],
          isUrgent: extra['isUrgent'],
        );
      },
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