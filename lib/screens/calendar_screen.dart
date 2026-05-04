import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Calendário',
          style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                  const Text(
                    'Maio 2026',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: CERESColors.textMain),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: CERESColors.textMain),
                        onPressed: () {},
                      ),
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

              // 
              _buildCalendarWeek(['27', '28', '29', '30', '1', '2', '3'], isFirstWeek: true, dots: ['1']),
              _buildCalendarWeek(['4', '5', '6', '7', '8', '9', '10'], dots: ['9']),
              _buildCalendarWeek(['11', '12', '13', '14', '15', '16', '17'], selectedDate: '16', dots: ['16']),
              _buildCalendarWeek(['18', '19', '20', '21', '22', '23', '24'], dots: ['23']),
              _buildCalendarWeek(['25', '26', '27', '28', '29', '30', '31'], isLastWeek: true),
              
              const SizedBox(height: 32),

              // --- TÍTULO DA LISTA DO DIA ---
              const Text(
                'Quinta, 16 de maio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain),
              ),
              const SizedBox(height: 16),

              // --- LISTA DE TAREFAS DO DIA ---
              _buildTaskCard('Monstera', 'Rega recomendada', true),
              const SizedBox(height: 12),
              _buildTaskCard('Ficus Lyrata', 'Rega recomendada', true),
              const SizedBox(height: 12),
              _buildTaskCard('Samambaia', 'Não necessita de rega', false),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Constrói uma linha de 7 dias
  Widget _buildCalendarWeek(List<String> days, {String? selectedDate, List<String> dots = const [], bool isFirstWeek = false, bool isLastWeek = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.asMap().entries.map((entry) {
          int idx = entry.key;
          String day = entry.value;
          
          //lógica simples para pôr a cinzento os dias do mês anterior/seguinte
          bool isGreyDate = (isFirstWeek && (idx == 0 || idx == 1)) || (isLastWeek && (idx == 5 || idx == 6));
          bool isSelected = day == selectedDate;
          bool hasDot = dots.contains(day) && !isGreyDate;

          return _CalendarDay(
            day: day,
            isSelected: isSelected,
            isGrey: isGreyDate,
            hasDot: hasDot,
          );
        }).toList(),
      ),
    );
  }

  // O Cartão da tarefa de rega (Design da Bottom List do Calendário)
  Widget _buildTaskCard(String plantName, String status, bool needsWater) {
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
            child: const Icon(Icons.park, color: Colors.grey), // Placeholder para foto
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                const SizedBox(height: 4),
                Text(
                  status, 
                  style: const TextStyle(fontSize: 14, color: CERESColors.textSecondary)
                ),
              ],
            ),
          ),
          // O Ícone da Gota de água contornado
          Icon(
            Icons.water_drop_outlined, 
            color: needsWater ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen, // Laranja se precisar, Verde se não
            size: 28,
          ),
        ],
      ),
    );
  }
}

//widget auxiliar para os dias da semana em cima (Seg, Ter, Quar, Quin, Sext, Sab, Dom)
class _WeekDayText extends StatelessWidget {
  final String text;
  const _WeekDayText(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: CERESColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

//widget auxiliar para desenhar o quadrado de cada dia do calendário
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
    return SizedBox(
      width: 40,
      height: 45,
      child: Column(
        children: [
          // A bolinha do dia
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? CERESColors.primaryDarkGreen : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Colors.white 
                    : (isGrey ? Colors.grey.shade400 : CERESColors.textMain),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // O pontinho verde por baixo (se houver rega nesse dia)
          if (hasDot)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: CERESColors.primaryDarkGreen,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 4), // Espaço vazio para não estragar o alinhamento
        ],
      ),
    );
  }
}