import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class MainNavScreen extends StatelessWidget {
  
  // O "NavigationShell" é o maestro da nossa barra de navegação inferior criado pelo go_router.
  // Ele é "Stateful", o que significa que ele tem memória! 
  // Se fizeres scroll na página do Calendário, fores ao Perfil, e voltares ao Calendário... 
  // O Calendário vai estar exatamente no mesmo sítio onde o deixaste.
  final StatefulNavigationShell navigationShell;

  const MainNavScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // O "body" é simplesmente a página que o go_router diz que deve estar aberta agora
      body: navigationShell,
      
      // --- BOTÃO FLUTUANTE (FAB) ---
      // A lógica genial aqui: currentIndex == 0 significa que estamos no "Início" (Home).
      // Só mostramos o botão gigante de Adicionar Planta se estivermos no Início.
      // Nas outras abas (Perfil, Calendário, etc), o botão desaparece (passa a null).
      floatingActionButton: navigationShell.currentIndex == 0 
        ? FloatingActionButton(
            onPressed: () {
              context.push('/add-plant');
            },
            backgroundColor: CERESColors.primaryDarkGreen,
            shape: const CircleBorder(), // Fica redondinho perfeito
            elevation: 4, // Dá-lhe uma sombra para parecer que está a flutuar
            child: const Icon(Icons.add, color: Colors.white, size: 28),  
          ) 
        : null,
      
      // --- BARRA DE NAVEGAÇÃO INFERIOR ---
      bottomNavigationBar: Container(
        // Envolvemos a BottomNavigationBar num Container para lhe podermos dar esta sombra 
        // a apontar para cima (offset negativo no Y: -5), que a separa bem do resto do ecrã
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          // Type fixed impede que os ícones andem a "dançar" e a mudar de tamanho quando clicas neles
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0, // Tiramos a sombra padrão porque já fizemos uma melhor ali em cima
          
          currentIndex: navigationShell.currentIndex, // Diz à barra qual é o ícone que deve estar verde
          
          selectedItemColor: CERESColors.primaryDarkGreen,
          unselectedItemColor: Colors.grey.shade400,
          
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          
          // O que acontece quando clicas num ícone lá em baixo
          onTap: (index) {
            navigationShell.goBranch(
              index,
              // Truque espetacular de UX (User Experience): 
              // Se já estás na página "Plantas" e clicas no ícone "Plantas" outra vez, 
              // ele limpa o histórico dessa aba e volta à raiz (faz scroll pro topo ou fecha detalhes).
              // Se clicares numa aba diferente, ele simplesmente muda de aba.
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          
          // A lista das nossas 5 secções principais
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Início'),
            BottomNavigationBarItem(icon: Icon(Icons.eco_outlined), label: 'Plantas'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Calendário'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Estatísticas'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}