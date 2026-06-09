import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

// O ecrã de Ajuda é estático (StatelessWidget) porque serve apenas para apresentar informação.
// Não há interações com bases de dados, nem caixas de texto, nem estados que mudem ao longo do tempo.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // O clássico botão de voltar do GoRouter
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CERESColors.textMain),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ajuda e Suporte', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      
      // A página inteira é uma lista para garantir que faz scroll perfeitamente 
      // em telemóveis pequenos.
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          
          // --- 1. PERGUNTAS FREQUENTES ---
          const Text('Perguntas Frequentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 16),
          
          // Chamamos o nosso widget ajudante (_buildFaqItem) para desenhar os "acordeões".
          // Isto limpa muito a confusão visual neste ficheiro!
          _buildFaqItem(
            'Como adiciono uma planta?',
            'No ecrã inicial, clica no botão verde redondo com o símbolo "+" localizado no canto inferior direito.',
          ),
          _buildFaqItem(
            'Como sei que devo regar?',
            'A app analisa a data da última rega. Se uma planta precisar de água, ela aparecerá na secção "Hoje" e o alerta da gota de água mudará para a cor Laranja.',
          ),
          _buildFaqItem(
            'Como funciona a Meteorologia?',
            'O CERES usa as tuas coordenadas para consultar a Open-Meteo. Se houver previsão de chuva forte ou sol intenso, um banner amarelo aparecerá no topo do teu ecrã Inicial.',
          ),

          const SizedBox(height: 40),

          // --- 2. ÁREA DE CONTACTO ---
          const Text('Ainda precisas de ajuda?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 16),
          
          // Cartão de email com fundo verde clarinho
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CERESColors.primaryDarkGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CERESColors.primaryDarkGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                // Ícone redondo à esquerda
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.email_outlined, color: CERESColors.primaryDarkGreen),
                ),
                const SizedBox(width: 16),
                
                // Texto do email
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contacta a nossa equipa', style: TextStyle(fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                      SizedBox(height: 4),
                      Text('suporte@ceresapp.pt', style: TextStyle(color: CERESColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          const Divider(color: Color(0xFFEEEEEE)), // Divisória subtil
          const SizedBox(height: 32),

          // --- 3. CRÉDITOS ACADÉMICOS ---
          const Center(
            child: Text('SOBRE O PROJETO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CERESColors.textSecondary, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 24),
          
          // Logotipo da app um pouco transparente (opacity 0.5) para não "gritar" no fundo da página
          Center(
            child: Image.asset('assets/images/ceres_logo_only_2.png', height: 40, opacity: const AlwaysStoppedAnimation(0.5)),
          ),
          const SizedBox(height: 16),
          
          // O contexto académico do projeto (Dá logo outro nível à aplicação!)
          const Text(
            'A CERES foi desenvolvida no âmbito da Unidade Curricular de Computação Móvel (LEI) no Instituto Politécnico de Setúbal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CERESColors.textSecondary, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          // Caixa final com os nomes da equipa
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
            child: const Column(
              children: [
                Text('Desenvolvido por:', style: TextStyle(fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                SizedBox(height: 12),
                
                // A equipa de Elite!
                Text('Diogo Araújo', style: TextStyle(color: CERESColors.textSecondary, height: 1.8)),
                Text('Gonçalo França', style: TextStyle(color: CERESColors.textSecondary, height: 1.8)),
                Text('Jaime Rosado', style: TextStyle(color: CERESColors.textSecondary, height: 1.8)),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Número da versão, essencial para troubleshooting no futuro
          const Center(
            child: Text('Versão 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- WIDGET AJUDANTE (FAQ ITEM) ---
  // Uma função que cria aquelas caixas (ExpansionTiles) que abrem e fecham.
  // Criar isto aqui poupa dezenas de linhas de código lá em cima.
  Widget _buildFaqItem(String question, String answer) {
    return Theme(
      // Truque de UI: O Flutter por defeito põe uma linha horrível no topo e no fundo 
      // de um ExpansionTile quando ele é clicado. O Theme > dividerColor tira isso!
      data: ThemeData(dividerColor: Colors.transparent), 
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero, // Remove as margens laterais padrão para alinhar com o texto
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, color: CERESColors.textMain)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(answer, style: const TextStyle(color: CERESColors.textSecondary, height: 1.4)),
          )
        ],
      ),
    );
  }
}