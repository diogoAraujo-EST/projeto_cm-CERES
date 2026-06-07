import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'login_bottom_sheet.dart';     
import 'register_bottom_sheet.dart';  

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // --- NAVEGAÇÃO DOS BOTTOM SHEETS ---
  // Criamos funções aqui para abrir as abas de Login/Registo para podermos 
  // passar a lógica de navegação "de uma para a outra" como parâmetro.
  
  void _showLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Garante que a aba pode subir se o teclado abrir
      backgroundColor: Colors.transparent, // Transparente para podermos desenhar os cantos arredondados dentro do widget LoginBottomSheet
      builder: (context) => LoginBottomSheet(
        // E o que acontece se o utilizador estiver na aba de Login mas clicar em "Não tenho conta"?
        onSwitchToRegister: () {
          Navigator.pop(context); // 1. Fecha a aba de Login
          _showRegisterSheet(context); // 2. Abre a aba de Registo!
        },
      ),
    );
  }

  void _showRegisterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RegisterBottomSheet(
        // A lógica inversa da de cima:
        onSwitchToLogin: () {
          Navigator.pop(context); // 1. Fecha a aba de Registo
          _showLoginSheet(context); // 2. Abre a aba de Login!
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- DESIGN RESPONSIVO ---
    // Apanhamos o tamanho total do ecrã do telemóvel para podermos posicionar a planta gigante
    // e os textos em posições relativas (ex: "ocupar 50% da largura") em vez de tamanhos fixos.
    // Assim, o design não quebra se for um iPhone mini ou um Max.
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, 
      
      // Um "Stack" funciona como as camadas do Photoshop.
      // O que está primeiro na lista fica no fundo, o que vem a seguir é desenhado por cima.
      body: Stack(
        children: [
          
          // --- CAMADA 1: A PLANTA GIGANTE DE FUNDO ---
          // Positioned permite-nos colar um widget exatamente onde queremos usando as coordenadas do ecrã
          Positioned(
            // Um truque de design: Colocamos a imagem num valor negativo (-0.85) à esquerda
            // Isto faz com que a planta fique "cortada", espreitando apenas a partir do lado esquerdo do ecrã!
            left: -screenWidth * 0.85, 
            top: screenHeight * 0.10, 
            bottom: screenHeight * 0.35, 
            child: Image.asset(
              'assets/images/planta_welcome.png',
              fit: BoxFit.contain, // Garante que a folha não fica espalmada nem distorcida
            ),
          ),
          
          // --- CAMADA 2: O TEXTO E O LOGO ---
          Positioned(
            right: 24, // Encosta este bloco ao lado direito do ecrã
            top: screenHeight * 0.25, // Começa a 25% da altura total do ecrã
            width: screenWidth * 0.52, // Dá-lhe apenas metade do ecrã para ele não esmagar a folha de fundo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // O Logotipo pequeno por cima do texto
                Image.asset(
                  'assets/images/ceres_logo_only_2.png',
                  height: 80,
                  width: 60,
                  fit: BoxFit.contain,
                ),
                
                // RichText é espetacular quando queremos misturar estilos diferentes na mesma frase.
                // Aqui queremos a palavra "plantas" a verde e o resto a preto.
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 38, 
                      fontWeight: FontWeight.bold, 
                      color: CERESColors.textMain, 
                      height: 1.1, // Altura da linha um bocadinho mais apertada para o texto ficar juntinho
                    ),
                    children: [
                      TextSpan(text: 'Cuida\ndas tuas\n'),
                      TextSpan(
                        text: 'plantas', 
                        style: TextStyle(color: CERESColors.primaryDarkGreen), // Só a palavra "plantas" leva a cor verde!
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Subtítulo
                const Text(
                  'A rega certa,\nna altura certa.',
                  style: TextStyle(
                    fontSize: 16,
                    color: CERESColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          // --- CAMADA 3: OS BOTÕES NO FUNDO DO ECRÃ ---
          // O Align empurra tudo o que estiver lá dentro diretamente para o chão do telemóvel
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // bottom: 40 para não colar os botões à zona onde se faz "swipe up" no telemóvel
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Impede que esta coluna tente ocupar o ecrã todo para cima
                children: [
                  
                  // Botão Primário (Registo / Começar)
                  SizedBox(
                    width: double.infinity, // Ocupa a largura total até bater nas margens
                    child: ElevatedButton(
                      onPressed: () => _showRegisterSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CERESColors.primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Começar', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Botão Secundário (Login / Entrar)
                  // Usamos um OutlinedButton para ser menos chamativo que o botão de Registar, guiando
                  // os utilizadores novos para o botão principal e os velhos para este.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showLoginSheet(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Entrar', style: TextStyle(fontSize: 16, color: CERESColors.textMain, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}