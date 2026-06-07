import 'package:flutter/material.dart';

// O "Livro de Marca" da app. 
// Guardamos todas as cores aqui como "static const" para não gastar memória 
// a recriar a cor sempre que um botão for desenhado no ecrã.
class CERESColors {
  
  // A cor da identidade da CERES. É usada nos botões principais, nos ícones de tab, etc.
  static const Color primaryDarkGreen = Color(0xFF2B5336); // verde escuro dos botões
  
  // Um branco ligeiramente creme ("off-white"). É excelente para fundos porque 
  // corta aquele brilho excessivo do branco puro, tornando a app mais confortável aos olhos.
  static const Color backgroundCream = Color(0xFFF9F9F6); // Fundo 
  
  // Truque de Design: Nunca uses preto puro (0xFF000000) em apps modernas. 
  // Um cinza quase preto (1E1E1E) reduz o contraste agressivo com o fundo branco e cansa menos a vista.
  static const Color textMain = Color(0xFF1E1E1E);
  
  // A cor para os detalhes, datas e subtítulos (ajuda a criar hierarquia de leitura)
  static const Color textSecondary = Color(0xFF7A7A7A);
  
  // O Laranja de "Alerta". Usaste muito bem esta cor no lugar de um Vermelho puro. 
  // O vermelho significa "Erro/Perigo", enquanto o laranja significa "Atenção/Ação necessária" (Regar a planta).
  static const Color alertOrange = Color(0xFFD9774B); // Cor Alertas
  
  // O branco puro usado nos "Cards" (Cartões) para eles saltarem e ganharem destaque 
  // face ao fundo creme da aplicação.
  static const Color surfaceWhite = Colors.white; // Cartões
}