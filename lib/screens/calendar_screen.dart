import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // O Mês e Ano que estamos a visualizar atualmente
  DateTime _focusedMonth = DateTime.now();
  // O Dia exato em que o utilizador clicou
  DateTime _selectedDate = DateTime.now();

  // Função auxiliar para ver se duas datas são no mesmo dia ignorando horas
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Descobre todos os dias do mês atual que vamos desenhar na grelha
  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Ajusta para o calendário começar sempre na Segunda-feira
    final daysBefore = firstDayOfMonth.weekday - 1;
    final firstDayToDisplay = firstDayOfMonth.subtract(Duration(days: daysBefore));

    List<DateTime> days = [];
    // Desenha 5 semanas exatas (35 dias) para o calendário não mudar de tamanho
    for (int i = 0; i < 35; i++) {
      days.add(firstDayToDisplay.add(Duration(days: i)));
    }
    return days;
  }

  void _previousMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  }

  void _nextMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    final daysToDisplay = _getDaysInMonth(_focusedMonth);
    
    // Meses em Português
    final List<String> monthNames = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Calendário', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // O STREAMBUILDER Ouve o Firebase em tempo real
      body: StreamBuilder<List<UserPlant>>(
        stream: _firestoreService.getUserPlants(),
          builder: (context, snapshot) {
          // --- O SEGREDO DO SMOOTHNESS AQUI ---
          // Em vez de mostrar o loading sempre que pisca, só mostra o loading 
          // SE não tiver NENHUM DADO velho guardado na memória.
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          if (snapshot.hasError) {
             // Tratamento de erro mantém-se igual
          }

          // Se já tem dados (mesmo que o state seja waiting de um rebuild), ele usa-os!
          final plants = snapshot.data ?? [];

          // ---- A LÓGICA DE OURO DO CALENDÁRIO ----
          // Descobre as datas exatas das futuras regas de TODAS as plantas
          List<DateTime> allWateringDates = [];
          
          for (var plant in plants) {
            // Calcula a próxima rega teórica
            DateTime nextRega = plant.lastWatered.add(Duration(days: plant.wateringInterval));
            
            // Mas no calendário não queremos só a próxima rega, queremos ver o mês todo!
            // Então vamos projetar as regas até ao fim do mês atual selecionado
            DateTime tempDate = nextRega;
            while (tempDate.isBefore(DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0))) {
              allWateringDates.add(DateTime(tempDate.year, tempDate.month, tempDate.day));
              tempDate = tempDate.add(Duration(days: plant.wateringInterval));
            }

            // O nosso Modelo é inteligente e diz-nos se a planta já devia ter sido regada ANTES de hoje
            if (plant.isUrgent) {
              allWateringDates.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
            }
          }

          // Filtra as plantas que precisam de rega APENAS para o dia selecionado (_selectedDate)
          final List<UserPlant> plantsToWaterToday = plants.where((plant) {
            // Verifica se hoje está atrasado
            if (isSameDay(_selectedDate, DateTime.now()) && plant.isUrgent) return true;
            
            // Verifica as regas projetadas para este dia selecionado
            DateTime tempDate = plant.lastWatered.add(Duration(days: plant.wateringInterval));
            while (tempDate.isBefore(_selectedDate.add(const Duration(days: 1)))) {
              if (isSameDay(tempDate, _selectedDate)) return true;
              tempDate = tempDate.add(Duration(days: plant.wateringInterval));
            }
            return false;
          }).toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // --- SELETOR DE MÊS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${monthNames[_focusedMonth.month]} ${_focusedMonth.year}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain),
                      ),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.chevron_left, color: CERESColors.textMain), onPressed: _previousMonth),
                          IconButton(icon: const Icon(Icons.chevron_right, color: CERESColors.textMain), onPressed: _nextMonth),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- DIAS DA SEMANA ---
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WeekDayText('Seg'), _WeekDayText('Ter'), _WeekDayText('Qua'),
                      _WeekDayText('Qui'), _WeekDayText('Sex'), _WeekDayText('Sáb'), _WeekDayText('Dom'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- GRELHA DO CALENDÁRIO ---
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, // 7 dias da semana
                      childAspectRatio: 0.8, // Ajusta a altura de cada quadrado
                    ),
                    itemCount: daysToDisplay.length,
                    itemBuilder: (context, index) {
                      final day = daysToDisplay[index];
                      final isSelected = isSameDay(day, _selectedDate);
                      final isGrey = day.month != _focusedMonth.month; // Se não for do mês atual, fica cinzento
                      
                      // Verifica se o dia desenhado está na lista das regas (Ganha o Ponto Verde!)
                      final hasDot = allWateringDates.any((d) => isSameDay(d, day));

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = day;
                            // Se clicares num dia cinzento do mês passado/seguinte, o calendário salta para esse mês
                            if (day.month != _focusedMonth.month) {
                              _focusedMonth = DateTime(day.year, day.month, 1);
                            }
                          });
                        },
                        child: _CalendarDay(
                          day: day.day.toString(),
                          isSelected: isSelected,
                          isGrey: isGrey,
                          hasDot: hasDot,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),

                  // --- TÍTULO DA LISTA DO DIA ---
                  Text(
                    '${isSameDay(_selectedDate, DateTime.now()) ? 'Hoje, ' : ''}${_selectedDate.day} de ${monthNames[_selectedDate.month]}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain),
                  ),
                  const SizedBox(height: 16),

                  // --- LISTA DE TAREFAS DO DIA ---
                  if (plantsToWaterToday.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                      child: const Column(
                        children: [
                          Icon(Icons.sentiment_satisfied_alt, color: Colors.grey, size: 40),
                          SizedBox(height: 12),
                          Text('Nenhuma rega para hoje!', style: TextStyle(color: CERESColors.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    ...plantsToWaterToday.map((plant) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildTaskCard(plant.nickname, 'Rega agendada', true, plant.imageUrl),
                    )),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  // O Cartão da tarefa de rega (com a imagem do Firebase agora)
  Widget _buildTaskCard(String plantName, String status, bool needsWater, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.park, color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                const SizedBox(height: 4),
                Text(status, style: const TextStyle(fontSize: 14, color: CERESColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.water_drop_outlined, color: needsWater ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen, size: 28),
        ],
      ),
    );
  }
}

class _WeekDayText extends StatelessWidget {
  final String text;
  const _WeekDayText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(color: CERESColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)));
  }
}

class _CalendarDay extends StatelessWidget {
  final String day;
  final bool isSelected;
  final bool isGrey;
  final bool hasDot;

  const _CalendarDay({
    required this.day,
    this.isSelected = false,
    this.isGrey = false,
    this.hasDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: isSelected ? CERESColors.primaryDarkGreen : Colors.transparent, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            day,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : (isGrey ? Colors.grey.shade400 : CERESColors.textMain),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (hasDot)
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: CERESColors.primaryDarkGreen, shape: BoxShape.circle))
        else
          const SizedBox(height: 4), 
      ],
    );
  }
}