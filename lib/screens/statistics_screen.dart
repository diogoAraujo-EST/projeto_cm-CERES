import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
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
      body: StreamBuilder<List<UserPlant>>(
        stream: _firestoreService.getUserPlants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          final plants = snapshot.data ?? [];

          if (plants.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Adiciona plantas para começares a ver as tuas estatísticas de rega! 🌿', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: CERESColors.textSecondary, height: 1.5)),
              ),
            );
          }

          // 1. Planta Mais Regada
          UserPlant mostWateredPlant = plants.reduce((curr, next) => curr.wateringInterval < next.wateringInterval ? curr : next);

          // 2. Consistência (Baseada no Histórico Real de Falhas)
          double totalConsistency = 0;
          int validPlants = 0;

          for (var p in plants) {
            if (p.wateringHistory.isEmpty) continue;

            // O dia em que a planta foi registada na app
            DateTime birthDate = p.wateringHistory.first;
            int daysAlive = DateTime.now().difference(birthDate).inDays;

            // Quantas vezes devia ter sido regada até hoje? (Soma-se 1 da rega inicial)
            double expectedWaterings = (daysAlive / p.wateringInterval) + 1;

            // Quantas vezes foi realmente regada?
            int actualWaterings = p.wateringHistory.length;

            // Calcula o score desta planta (limita a 100% caso o utilizador regue dias a mais por engano)
            double plantConsistency = actualWaterings / expectedWaterings;
            if (plantConsistency > 1.0) plantConsistency = 1.0;

            totalConsistency += plantConsistency;
            validPlants++;
          }

          // Média de todas as plantas
          double consistency = validPlants > 0 ? (totalConsistency / validPlants) : 1.0;
          int consistencyPercentage = (consistency * 100).round();
          
          String consistencyText = 'Ótimo! 🎉';
          String consistencySub = 'Manténs uma ótima rotina de rega.';
          if (consistency < 0.6) {
            consistencyText = 'Atenção! ⚠️';
            consistencySub = 'Tens falhado muitas regas.';
          } else if (consistency < 0.85) {
            consistencyText = 'Quase lá! 🌱';
            consistencySub = 'Tenta não te atrasar tantos dias.';
          }

          // 3. O MOTOR DOS GRÁFICOS (Lê apena a Última Rega real registada na BD)
          String regasText = '';
          List<Widget> chartBars = [];
          DateTime now = DateTime.now();

          if (_selectedTab == 0) {
            // VERIFICA APENAS ESTA SEMANA
            List<int> weekData = List.filled(7, 0);
            DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
            DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
            
            for(var p in plants) {
               for(var pastRega in p.wateringHistory) {
                 if (!pastRega.isBefore(startOfWeek) && !pastRega.isAfter(endOfWeek)) {
                   weekData[pastRega.weekday - 1]++;
                 }
               }
            }
            
            int total = weekData.fold(0, (a, b) => a + b);
            regasText = '$total esta semana';
            
            int maxVal = weekData.reduce((a, b) => a > b ? a : b);
            if (maxVal == 0) maxVal = 1; 
            
            List<String> labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
            for (int i = 0; i < 7; i++) {
               double h = (weekData[i] / maxVal) * 120;
               if (weekData[i] > 0 && h < 15) h = 15; 
               chartBars.add(_buildDynamicBar(h, labels[i]));
            }
          } 
          else if (_selectedTab == 1) {
            // VERIFICA APENAS ESTE MÊS
            List<int> monthData = List.filled(4, 0);
            DateTime startOfMonth = DateTime(now.year, now.month, 1);
            DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59);
            
            for(var p in plants) {
               for(var pastRega in p.wateringHistory) {
                 if (!pastRega.isBefore(startOfMonth) && !pastRega.isAfter(endOfMonth)) {
                   int weekIndex = (pastRega.day - 1) ~/ 7;
                   if (weekIndex > 3) weekIndex = 3; 
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
          else {
            // VERIFICA APENAS ESTE ANO
            List<int> yearData = List.filled(4, 0);
            DateTime startOfYear = DateTime(now.year, 1, 1);
            DateTime endOfYear = DateTime(now.year, 12, 31, 23, 59);
            
            for(var p in plants) {
               for(var pastRega in p.wateringHistory) {
                 if (!pastRega.isBefore(startOfYear) && !pastRega.isAfter(endOfYear)) {
                   int trimIndex = (pastRega.month - 1) ~/ 3; 
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

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            children: [
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

              Container(
                height: 200,
                padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 70, height: 70, 
                          child: CircularProgressIndicator(
                            value: consistency, 
                            backgroundColor: Colors.grey.shade100, 
                            color: consistency < 0.5 ? CERESColors.alertOrange : CERESColors.primaryDarkGreen, 
                            strokeWidth: 8, 
                            strokeCap: StrokeCap.round
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
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? CERESColors.primaryDarkGreen : CERESColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildDynamicBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24, 
          height: height, 
          decoration: BoxDecoration(
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