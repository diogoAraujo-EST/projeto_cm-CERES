import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';

// Este ecrã é Stateful porque precisamos de guardar a tab que o utilizador 
// selecionou no gráfico (Semana / Mês / Ano) e atualizar o gráfico quando ele clica.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Começa no índice 0 (A tab "Semana")
  int _selectedTab = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Estatísticas', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      
      // Abre a ligação em tempo real ao Firebase
      body: StreamBuilder<List<UserPlant>>(
        stream: _firestoreService.getUserPlants(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          final plants = snapshot.data ?? [];

          // "Empty State" elegante: Se não há plantas, não há estatísticas para mostrar!
          if (plants.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Adiciona plantas para começares a ver as tuas estatísticas de rega! 🌿', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: CERESColors.textSecondary, height: 1.5)),
              ),
            );
          }

          // --- 1. PLANTA MAIS REGADA ---
          // Em vez de fazermos um loop 'for' gigante, usamos o método `.reduce` para comparar
          // as plantas 2 a 2 até sobrar a "vencedora" (aquela com o menor wateringInterval).
          UserPlant mostWateredPlant = plants.reduce((curr, next) => curr.wateringInterval < next.wateringInterval ? curr : next);

          // --- 2. CÁLCULO DE CONSISTÊNCIA DE REGA ---
          // Esta lógica descobre a percentagem de vezes que o utilizador regou a planta quando devia.
          double totalConsistency = 0;
          int validPlants = 0;

          for (var p in plants) {
            if (p.wateringHistory.isEmpty) continue; // Ignora plantas acabadas de criar

            // Para saber quantas vezes a planta DEVERIA ter sido regada, 
            // precisamos de saber há quanto tempo o utilizador a adicionou à app.
            DateTime birthDate = p.wateringHistory.first; 
            int daysAlive = DateTime.now().difference(birthDate).inDays;

            // Matemática: (Dias Viva / Intervalo de Rega) + 1 (A rega do dia em que foi criada)
            double expectedWaterings = (daysAlive / p.wateringInterval) + 1;

            // Quantas vezes foi REALMENTE regada? (Lemos isto da array que guardamos no Firebase)
            int actualWaterings = p.wateringHistory.length;

            // Score desta planta individual
            double plantConsistency = actualWaterings / expectedWaterings;
            // Se o utilizador andou a regar à toa e regou 5 vezes quando só devia ter regado 2,
            // cortamos em 1.0 (100%) para não rebentar a matemática do gráfico circular.
            if (plantConsistency > 1.0) plantConsistency = 1.0;

            totalConsistency += plantConsistency;
            validPlants++;
          }

          // Calcula a média geral
          double consistency = validPlants > 0 ? (totalConsistency / validPlants) : 1.0;
          int consistencyPercentage = (consistency * 100).round(); // Arredonda a nota para não mostrar tipo "83.4242%"
          
          // Prepara a mensagem de feedback consoante a nota que o utilizador tirou!
          String consistencyText = 'Ótimo! 🎉';
          String consistencySub = 'Manténs uma ótima rotina de rega.';
          if (consistency < 0.6) {
            consistencyText = 'Atenção! ⚠️';
            consistencySub = 'Tens falhado muitas regas.';
          } else if (consistency < 0.85) {
            consistencyText = 'Quase lá! 🌱';
            consistencySub = 'Tenta não te atrasar tantos dias.';
          }

          // --- 3. O MOTOR DOS GRÁFICOS DE BARRAS ---
          String regasText = '';
          List<Widget> chartBars = []; // A lista onde vamos guardar os retângulos verdes para desenhar depois
          DateTime now = DateTime.now();

          // TAB: SEMANA
          if (_selectedTab == 0) {
            List<int> weekData = List.filled(7, 0); // Cria uma array com 7 zeros: [0,0,0,0,0,0,0]
            
            // Descobre o primeiro dia da semana atual
            DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
            // Descobre o último segundo de domingo
            DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
            
            // Varre o histórico todo e atira os pontos para o dia da semana certo (0 = Seg, 6 = Dom)
            for(var p in plants) {
               for(var pastRega in p.wateringHistory) {
                 if (!pastRega.isBefore(startOfWeek) && !pastRega.isAfter(endOfWeek)) {
                   weekData[pastRega.weekday - 1]++;
                 }
               }
            }
            
            // O '.fold' é um atalho para somar todos os valores dentro da array de uma vez
            int total = weekData.fold(0, (a, b) => a + b);
            regasText = '$total esta semana';
            
            // Descobre qual é a barra mais alta para podermos nivelar as outras por ela
            int maxVal = weekData.reduce((a, b) => a > b ? a : b);
            if (maxVal == 0) maxVal = 1; // Previne divisão por zero se não houver regas!
            
            List<String> labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
            
            // Constrói os 7 retângulos visuais
            for (int i = 0; i < 7; i++) {
               // A altura máxima do gráfico é 120 pixels. A regra de três simples ajusta as barras!
               double h = (weekData[i] / maxVal) * 120;
               // Se a pessoa regou 1 vez, não queremos que a barra fique tão pequenina que não se veja. 
               // Forçamos um mínimo de 15px.
               if (weekData[i] > 0 && h < 15) h = 15; 
               chartBars.add(_buildDynamicBar(h, labels[i]));
            }
          } 
          
          // TAB: MÊS
          else if (_selectedTab == 1) {
            List<int> monthData = List.filled(4, 0); // 4 semanas no mês
            DateTime startOfMonth = DateTime(now.year, now.month, 1);
            DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59); // Truque: "dia 0" do mês seguinte = último dia deste mês
            
            for(var p in plants) {
               for(var pastRega in p.wateringHistory) {
                 if (!pastRega.isBefore(startOfMonth) && !pastRega.isAfter(endOfMonth)) {
                   int weekIndex = (pastRega.day - 1) ~/ 7; // Separa os dias do mês em caixas de 7 em 7
                   if (weekIndex > 3) weekIndex = 3; // O mês tem uns dias soltos no fim (29, 30, 31). Atiramos esses pra semana 4.
                   monthData[weekIndex]++;
                 }
               }
            }
            
            int total = monthData.fold(0, (a, b) => a + b);
            regasText = '$total este mês';
            int maxVal = monthData.reduce((a, b) => a > b ? a : b);
            if (maxVal == 0) maxVal = 1;
            
            List<String> labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
            for (int i = 0; i < 4; i++) {
               double h = (monthData[i] / maxVal) * 120;
               if (monthData[i] > 0 && h < 15) h = 15;
               chartBars.add(_buildDynamicBar(h, labels[i]));
            }
          } 
          
          // TAB: ANO
          else {
            List<int> yearData = List.filled(4, 0); // 4 trimestres
            DateTime startOfYear = DateTime(now.year, 1, 1);
            DateTime endOfYear = DateTime(now.year, 12, 31, 23, 59);
            
            for(var p in plants) {
               for(var pastRega in p.wateringHistory) {
                 if (!pastRega.isBefore(startOfYear) && !pastRega.isAfter(endOfYear)) {
                   int trimIndex = (pastRega.month - 1) ~/ 3; // Separa os 12 meses em grupos de 3 (Trimestres)
                   yearData[trimIndex]++;
                 }
               }
            }
            
            int total = yearData.fold(0, (a, b) => a + b);
            regasText = '$total este ano';
            int maxVal = yearData.reduce((a, b) => a > b ? a : b);
            if (maxVal == 0) maxVal = 1;
            
            List<String> labels = ['1º Trim', '2º Trim', '3º Trim', '4º Trim'];
            for (int i = 0; i < 4; i++) {
               double h = (yearData[i] / maxVal) * 120;
               if (yearData[i] > 0 && h < 15) h = 15;
               chartBars.add(_buildDynamicBar(h, labels[i]));
            }
          }

          // --- O DESENHO DO ECRÃ EM SI ---
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            children: [
              
              // O Seletor (Semana / Mês / Ano)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)),
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
              Text(regasText, style: const TextStyle(color: CERESColors.textSecondary)),
              const SizedBox(height: 16),

              // O GRÁFICO VISUAL
              Container(
                height: 200,
                padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // Para as barras começarem a subir de baixo para cima!
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: chartBars, // As barras que calculámos lá em cima
                ),
              ),
              
              const SizedBox(height: 32),
              
              // --- DESTAQUE DA PLANTA MAIS REGADA ---
              const Text('Planta mais regada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(mostWateredPlant.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.park, color: CERESColors.primaryDarkGreen)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mostWateredPlant.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                        Text('Rega a cada ${mostWateredPlant.wateringInterval} dias', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // --- CÍRCULO DE CONSISTÊNCIA ---
              const Text('Consistência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(consistencyText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                          const SizedBox(height: 8),
                          Text(consistencySub, style: const TextStyle(color: CERESColors.textSecondary, height: 1.4)),
                        ],
                      ),
                    ),
                    
                    // Um Stack para sobrepor o número "100%" ao anel redondo
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70, height: 70, 
                          // O gráfico circular (Ring Chart) nativo do Flutter!
                          child: CircularProgressIndicator(
                            value: consistency, // Aqui entra o valor entre 0.0 e 1.0!
                            backgroundColor: Colors.grey.shade100, 
                            color: consistency < 0.5 ? CERESColors.alertOrange : CERESColors.primaryDarkGreen, 
                            strokeWidth: 8, // A grossura da "linha" do anel
                            strokeCap: StrokeCap.round // Fica com as pontas redondas e suaves em vez de cortadas a direito
                          )
                        ),
                        Text('$consistencyPercentage%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        }
      ),
    );
  }

  // --- WIDGET AJUDANTE (O botão de tab que muda de cor) ---
  Widget _buildTabButton(String title, int tabIndex) {
    bool isSelected = _selectedTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            // Se estiver selecionado, damos-lhe uma sombra para parecer que é um botão elevado a flutuar na caixa
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? CERESColors.primaryDarkGreen : CERESColors.textSecondary)),
        ),
      ),
    );
  }

  // --- WIDGET AJUDANTE (O retângulo do gráfico) ---
  Widget _buildDynamicBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end, // Para empurrar a barra para o "chão" do gráfico
      children: [
        Container(
          width: 24, 
          height: height, // Esta foi a altura que o algoritmo calculou na regra de três simples
          decoration: BoxDecoration(
            // Se tiver zero de altura (0 regas), o fundo fica transparente.
            color: height > 0 ? CERESColors.primaryDarkGreen.withValues(alpha: 0.8) : Colors.transparent, 
            borderRadius: BorderRadius.circular(6)
          )
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}