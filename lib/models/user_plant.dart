import 'package:cloud_firestore/cloud_firestore.dart';

class UserPlant {
  final String id;
  final String userId;
  final String nickname;
  final String speciesName;
  final String imageUrl;
  final int wateringInterval;
  final DateTime lastWatered;
  final String roomName;
  final List<DateTime> wateringHistory; 
  
  // NOVOS CAMPOS DA API
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

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nickname': nickname,
      'speciesName': speciesName,
      'imageUrl': imageUrl,
      'wateringInterval': wateringInterval,
      'lastWatered': Timestamp.fromDate(lastWatered),
      'roomName': roomName,
      'wateringHistory': wateringHistory.map((d) => Timestamp.fromDate(d)).toList(),
      'apiLight': apiLight,
      'apiCare': apiCare,
      'apiDescription': apiDescription,
    };
  }

  factory UserPlant.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserPlant(
      id: doc.id,
      userId: data['userId'] ?? '',
      nickname: data['nickname'] ?? '',
      speciesName: data['speciesName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      wateringInterval: data['wateringInterval'] ?? 7,
      lastWatered: (data['lastWatered'] as Timestamp).toDate(),
      roomName: data['roomName'] ?? '',
      wateringHistory: (data['wateringHistory'] as List<dynamic>?)
          ?.map((t) => (t as Timestamp).toDate())
          .toList() ?? [(data['lastWatered'] as Timestamp).toDate()],
      
      // Fallbacks para plantas antigas criadas antes desta alteração
      apiLight: data['apiLight'] ?? 'Luz indireta',
      apiCare: data['apiCare'] ?? 'Rega regular.',
      apiDescription: data['apiDescription'] ?? 'Sem descrição disponível.',
    );
  }

  int get daysUntilNextWatering {
    final nextWatering = lastWatered.add(Duration(days: wateringInterval));
    final today = DateTime.now();
    final dateNext = DateTime(nextWatering.year, nextWatering.month, nextWatering.day);
    final dateToday = DateTime(today.year, today.month, today.day);
    return dateNext.difference(dateToday).inDays;
  }

  bool get isUrgent => daysUntilNextWatering <= 0;

  String get statusText {
    if (daysUntilNextWatering <= 0) return 'Precisa de rega';
    if (daysUntilNextWatering == 1) return 'Amanhã';
    return 'Em $daysUntilNextWatering dias';
  }

  String get lastWateredText {
    final today = DateTime.now();
    final dateLast = DateTime(lastWatered.year, lastWatered.month, lastWatered.day);
    final dateToday = DateTime(today.year, today.month, today.day);
    final diff = dateToday.difference(dateLast).inDays;
    
    if (diff == 0) return 'Última rega: Hoje';
    if (diff == 1) return 'Última rega: há 1 dia';
    return 'Última rega: há $diff dias';
  }
}