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
  // A nossa ponte para o Firebase para ir buscar as plantas
  final FirestoreService _firestoreService = FirestoreService();
  
  // Para sabermos que página do calendário estamos a ver (ex: Março de 2024)
  DateTime _focusedMonth = DateTime.now();
  
  // O dia exato em que o utilizador clicou (para ver a lista de tarefas lá em baixo)
  DateTime _selectedDate = DateTime.now();

  // Função super útil para comparar dias. 
  // O Dart por defeito compara milissegundos, por isso o mesmo dia às 10h e às 15h daria "falso". Assim ignoramos as horas.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // A matemática por trás da grelha do calendário.
  // Calcula os dias todos que vamos mostrar no ecrã (incluindo aqueles diazinhos cinzentos do mês anterior e seguinte)
  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    
    // Descobre em que dia da semana calha o dia 1 para puxar o calendário para trás até à Segunda-feira
    final daysBefore = firstDayOfMonth.weekday - 1;
    final firstDayToDisplay = firstDayOfMonth.subtract(Duration(days: daysBefore));

    List<DateTime> days = [];
    // Desenhamos exatamente 5 semanas (35 dias). 
    // Assim o calendário fica sempre do mesmo tamanho e os elementos em baixo não andam aos saltos entre meses.
    for (int i = 0; i < 35; i++) {
      days.add(firstDayToDisplay.add(Duration(days: i)));
    }
    return days;
  }

  // Atalhos para os botões das setinhas do calendário
  void _previousMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  }

  void _nextMonth() {
    setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    final daysToDisplay = _getDaysInMonth(_focusedMonth);
    
    // Um truque rápido para não termos de instalar bibliotecas de datas só para traduzir os meses
    // A posição 0 está vazia porque os meses no Dart começam no 1 (Janeiro)
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
      
      // O STREAMBUILDER Ouve a base de dados em tempo real. Se regares uma planta noutro ecrã, isto atualiza sozinho.
      body: StreamBuilder<List<UserPlant>>(
        stream: _firestoreService.getUserPlants(),
          builder: (context, snapshot) {
            
          // --- O SEGREDO PARA A APP NÃO PISCAR (SMOOTHNESS) ---
          // Em vez de mostrar a rodinha de loading sempre que há um pequeno update no Firebase,
          // só mostramos se NÃO tivermos NENHUM dado antigo guardado na memória.
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          if (snapshot.hasError) {
             // Tratamento de erro standard
          }

          // Apanhamos as plantas que vieram do Firebase. Se vier vazio, usamos uma lista [] vazia para não dar erro
          final plants = snapshot.data ?? [];

          // ---- A LÓGICA DE OURO DO CALENDÁRIO ----
          // Vamos varrer todas as plantas e descobrir em que dias do mês é que precisam de ser regadas
          List<DateTime> allWateringDates = [];
          
          for (var plant in plants) {
            // Rega base = última vez que bebeu + dias de intervalo
            DateTime nextRega = plant.lastWatered.add(Duration(days: plant.wateringInterval));
            
            // Aqui projetamos o futuro! 
            // Continuamos a somar o intervalo até passarmos o mês que o utilizador está a ver
            DateTime tempDate = nextRega;
            while (tempDate.isBefore(DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0))) {
              allWateringDates.add(DateTime(tempDate.year, tempDate.month, tempDate.day));
              tempDate = tempDate.add(Duration(days: plant.wateringInterval));
            }

            // Se a planta já estiver a secar (atrasada), marcamos o dia de HOJE como dia de rega obrigatória
            if (plant.isUrgent) {
              allWateringDates.add(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
            }
          }

          // Agora filtramos as plantas para mostrar só a lista lá em baixo correspondente ao DIA em que o utilizador clicou
          final List<UserPlant> plantsToWaterToday = plants.where((plant) {
            // 1. Se clicámos no dia de hoje e ela está urgente, entra na lista
            if (isSameDay(_selectedDate, DateTime.now()) && plant.isUrgent) return true;
            
            // 2. Ou então, simulamos as regas para ver se calha no dia selecionado
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
                  
                  // --- CABEÇALHO DO MÊS COM AS SETAS ---
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

                  // --- CABEÇALHO DOS DIAS DA SEMANA ---
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
                    shrinkWrap: true, // Importante para usar dentro do SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // O scroll já é feito pela página toda
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, // 7 colunas (uma para cada dia da semana)
                      childAspectRatio: 0.8, // Deixa as células um bocadinho mais altas do que largas para caber a bolinha verde
                    ),
                    itemCount: daysToDisplay.length,
                    itemBuilder: (context, index) {
                      final day = daysToDisplay[index];
                      final isSelected = isSameDay(day, _selectedDate);
                      final isGrey = day.month != _focusedMonth.month; // Pinta de cinzento se for do mês ao lado
                      
                      // Vê se este dia específico calhou na nossa lista de regas. Se sim, ganha o Pontinho Verde!
                      final hasDot = allWateringDates.any((d) => isSameDay(d, day));

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = day;
                            // Se o utilizador clicar num dos dias cinzentos, o calendário salta automaticamente para esse mês!
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

                  // --- TÍTULO DA ZONA DE TAREFAS ---
                  Text(
                    // Pequeno detalhe de UX: Se for hoje escreve "Hoje,", senão diz só o dia
                    '${isSameDay(_selectedDate, DateTime.now()) ? 'Hoje, ' : ''}${_selectedDate.day} de ${monthNames[_selectedDate.month]}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain),
                  ),
                  const SizedBox(height: 16),

                  // --- LISTA DE TAREFAS DESSE DIA ---
                  if (plantsToWaterToday.isEmpty)
                    // Se não há nada para fazer, mostramos um estado vazio agradável
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
                    // Se houver, desenhamos um cartão para cada planta que apareceu no filtro
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

  // --- COMPONENTES VISUAIS (WIDGETS) ---

  // O cartãozinho que diz qual é a planta a regar
  Widget _buildTaskCard(String plantName, String status, bool needsWater, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Uma sombrinha super suave para dar profundidade
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // A miniatura da foto da planta
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // Carrega a foto, se der erro mostra um ícone de árvore
              child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.park, color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 16),
          // O nome da planta (Expanded faz com que o texto ocupe o espaço do meio e empurre a gota para o canto)
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
          // A gota de água (que pode ficar laranja de urgência ou verde consoante a flag needsWater)
          Icon(Icons.water_drop_outlined, color: needsWater ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen, size: 28),
        ],
      ),
    );
  }
}

// O componente de texto estático para os dias da semana (Seg, Ter, Qua...)
class _WeekDayText extends StatelessWidget {
  final String text;
  const _WeekDayText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(color: CERESColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)));
  }
}

// O bloco visual de cada dia no calendário
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
        // O círculo à volta do número
        Container(
          width: 32,
          height: 32,
          // Fica verde se estiver selecionado, senão fica transparente
          decoration: BoxDecoration(color: isSelected ? CERESColors.primaryDarkGreen : Colors.transparent, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            day,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              // Lógica de cores: Selecionado -> Branco. Não selecionado -> Cinzento se for do mês ao lado, Escuro se for do mês atual.
              color: isSelected ? Colors.white : (isGrey ? Colors.grey.shade400 : CERESColors.textMain),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // O pontinho indicador de que há tarefas neste dia
        if (hasDot)
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: CERESColors.primaryDarkGreen, shape: BoxShape.circle))
        else
          const SizedBox(height: 4), // Placeholder para o layout não dar pulos quando o ponto aparece/desaparece
      ],
    );
  }
}