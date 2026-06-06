import 'package:flutter/material.dart';
import '../constants/colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Variável que guarda qual é a aba selecionada (0 = Semana, 1 = Mês, 2 = Ano)
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    
    // --- DADOS DINÂMICOS FALSOS PARA A APRESENTAÇÃO ---
    // Conforme a aba selecionada, mostramos números diferentes para impressionar o professor!
    String regasText = '';
    List<Widget> chartBars = [];

    if (_selectedTab == 0) {
      // DADOS DA SEMANA
      regasText = '12 esta semana';
      chartBars = [
        _buildFakeBar(50, 'Seg'), _buildFakeBar(90, 'Ter'), _buildFakeBar(70, 'Qua'),
        _buildFakeBar(110, 'Qui'), _buildFakeBar(100, 'Sex'), _buildFakeBar(40, 'Sáb'), _buildFakeBar(80, 'Dom'),
      ];
    } else if (_selectedTab == 1) {
      // DADOS DO MÊS
      regasText = '48 este mês';
      chartBars = [
        _buildFakeBar(100, 'Sem 1'), _buildFakeBar(80, 'Sem 2'), _buildFakeBar(120, 'Sem 3'), _buildFakeBar(90, 'Sem 4'),
      ];
    } else {
      // DADOS DO ANO
      regasText = '320 este ano';
      chartBars = [
        _buildFakeBar(60, '1º Trim'), _buildFakeBar(110, '2º Trim'), _buildFakeBar(130, '3º Trim'), _buildFakeBar(80, '4º Trim'),
      ];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Estatísticas', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        children: [
          
          // --- ABAS INTERATIVAS ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _buildTabButton('Semana', 0),
                _buildTabButton('Mês', 1),
                _buildTabButton('Ano', 2),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text('Regas realizadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 4),
          // O texto muda sozinho consoante a aba!
          Text(regasText, style: const TextStyle(color: CERESColors.textSecondary)),
          const SizedBox(height: 16),

          // --- GRÁFICO ---
          Container(
            height: 200, // <--- ERRO CORRIGIDO AQUI: Aumentei a altura da caixa para as barras não saírem fora!
            padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              // As barras mudam sozinhas consoante a aba!
              children: chartBars,
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('Planta mais regada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.park, color: CERESColors.primaryDarkGreen, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Samambaia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                    Text(_selectedTab == 0 ? '3 regas' : (_selectedTab == 1 ? '12 regas' : '65 regas'), style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Text('Consistência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ótimo! 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                      SizedBox(height: 8),
                      Text('Manténs uma ótima rotina de rega.', style: TextStyle(color: CERESColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: 0.9, backgroundColor: Colors.grey.shade100, color: CERESColors.primaryDarkGreen, strokeWidth: 8, strokeCap: StrokeCap.round)),
                    const Text('90%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGET PARA OS BOTÕES DAS ABAS ---
  Widget _buildTabButton(String title, int tabIndex) {
    bool isSelected = _selectedTab == tabIndex; // Verifica se esta aba é a selecionada
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabIndex; // Quando clica, atualiza o ecrã
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent, // Fica branco se selecionado
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? CERESColors.primaryDarkGreen : CERESColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET DAS BARRAS DO GRÁFICO ---
  Widget _buildFakeBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24, 
          height: height, 
          decoration: BoxDecoration(color: CERESColors.primaryDarkGreen.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(6))
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}