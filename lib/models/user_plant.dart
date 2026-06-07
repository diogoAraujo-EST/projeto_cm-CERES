import 'package:cloud_firestore/cloud_firestore.dart';

// Este modelo representa a planta física do utilizador, a que ele tem em casa.
// Não deve ser confundido com a "PlantSpecies", que é a enciclopédia teórica da API.
class UserPlant {
  // Identificação e referências
  final String id;          // O ID do documento na base de dados (Firestore)
  final String userId;      // A quem pertence esta planta
  
  // Informação Base
  final String nickname;    // O nome carinhoso (Ex: "A minha Monstera do quarto")
  final String speciesName; // A espécie biológica
  final String imageUrl;    // O link da foto (da API ou a que ele tirou com a câmara)
  
  // A Matemática das Regas
  final int wateringInterval; // A cada X dias (Já com as contas do motor de inteligência aplicadas)
  final DateTime lastWatered; // A data exata da última gota de água
  
  // Localização
  final String roomName;    // A divisão da casa onde ela mora
  
  // O Histórico
  // Guarda todas as datas em que o utilizador clicou em "Regar". É isto que alimenta o gráfico de estatísticas!
  final List<DateTime> wateringHistory; 
  
  // NOVOS CAMPOS DA API
  // Trazemos as dicas teóricas da espécie e guardamo-las dentro da própria planta do utilizador,
  // assim ele não gasta internet a ir buscar dicas à API cada vez que abre o ecrã de detalhes!
  final String apiLight;
  final String apiCare;
  final String apiDescription;

  UserPlant({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.speciesName,
    required this.imageUrl,
    required this.wateringInterval,
    required this.lastWatered,
    required this.roomName,
    required this.wateringHistory,
    required this.apiLight,
    required this.apiCare,
    required this.apiDescription,
  });

  // --- O TRADUTOR PARA O FIREBASE (ENVIAR) ---
  // A base de dados não entende o que é um objeto "UserPlant", só percebe dicionários (Maps).
  // E o Firebase tem uma pancada com as datas: não aceita DateTime do Dart, tem de ser convertido para "Timestamp".
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nickname': nickname,
      'speciesName': speciesName,
      'imageUrl': imageUrl,
      'wateringInterval': wateringInterval,
      'lastWatered': Timestamp.fromDate(lastWatered), // O tal ajuste de data!
      'roomName': roomName,
      // Faz o mesmo para a lista toda do histórico
      'wateringHistory': wateringHistory.map((d) => Timestamp.fromDate(d)).toList(),
      'apiLight': apiLight,
      'apiCare': apiCare,
      'apiDescription': apiDescription,
    };
  }

  // --- O TRADUTOR DO FIREBASE (RECEBER) ---
  // Quando a app descarrega os dados, usamos a "factory" para moldar as peças soltas num objeto UserPlant.
  factory UserPlant.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    return UserPlant(
      // O ID não vem dentro dos dados, é o nome do próprio documento, por isso pegamos dele do doc.id
      id: doc.id,
      userId: data['userId'] ?? '',
      nickname: data['nickname'] ?? '',
      speciesName: data['speciesName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      wateringInterval: data['wateringInterval'] ?? 7,
      
      // O processo inverso: passamos de Timestamp do Firebase de volta para o DateTime do Dart
      lastWatered: (data['lastWatered'] as Timestamp).toDate(),
      roomName: data['roomName'] ?? '',
      
      // Lista do histórico. Se a planta for velha e não tiver histórico, inventa uma lista
      // e mete lá dentro o dia da última rega para a app não crashar.
      wateringHistory: (data['wateringHistory'] as List<dynamic>?)
          ?.map((t) => (t as Timestamp).toDate())
          .toList() ?? [(data['lastWatered'] as Timestamp).toDate()],
      
      // Fallbacks para plantas antigas criadas antes de teres atualizado o modelo da App
      apiLight: data['apiLight'] ?? 'Luz indireta',
      apiCare: data['apiCare'] ?? 'Rega regular.',
      apiDescription: data['apiDescription'] ?? 'Sem descrição disponível.',
    );
  }

  // --- MÉTODOS DE INTELIGÊNCIA ---
  // Em vez de fazeres a matemática nos ecrãs, fazes aqui uma vez e usas a propriedade ".daysUntilNextWatering" à vontade.
  
  int get daysUntilNextWatering {
    // 1. Soma os dias do intervalo à data da última rega
    final nextWatering = lastWatered.add(Duration(days: wateringInterval));
    final today = DateTime.now();
    
    // 2. Apara as "horas" das datas para não termos bugs.
    // Se não aparássemos, o Dart dizia que da 1 da manhã de hoje até à meia-noite de amanhã faltam zero dias
    // (porque são só 23 horas), quando na verdade são dias de calendário diferentes.
    final dateNext = DateTime(nextWatering.year, nextWatering.month, nextWatering.day);
    final dateToday = DateTime(today.year, today.month, today.day);
    
    // 3. Subtrai
    return dateNext.difference(dateToday).inDays;
  }

  // É com isto que o NotificationScreen descobre quem precisa de aparecer!
  bool get isUrgent => daysUntilNextWatering <= 0;

  // Dá os nomes simpáticos para os cartões da Home
  String get statusText {
    if (daysUntilNextWatering <= 0) return 'Precisa de rega';
    if (daysUntilNextWatering == 1) return 'Amanhã';
    return 'Em $daysUntilNextWatering dias';
  }

  // A legenda cinzenta que aparece por baixo do estado
  String get lastWateredText {
    final today = DateTime.now();
    // O mesmo truque de aparar horas para o calendário fazer sentido à mente humana
    final dateLast = DateTime(lastWatered.year, lastWatered.month, lastWatered.day);
    final dateToday = DateTime(today.year, today.month, today.day);
    
    final diff = dateToday.difference(dateLast).inDays;
    
    if (diff == 0) return 'Última rega: Hoje';
    if (diff == 1) return 'Última rega: há 1 dia';
    return 'Última rega: há $diff dias';
  }
}