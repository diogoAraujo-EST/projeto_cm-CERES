import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';
import '../models/user_plant.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Adicionar Planta
  Future<void> addPlant(UserPlant plant) async {
    await _db.collection('plants').add(plant.toMap());
  }

  // Obter Plantas do Utilizador Logado (Stream em Tempo Real)
  Stream<List<UserPlant>> getUserPlants() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]); // Retorna lista vazia se não houver login

    return _db
        .collection('plants')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserPlant.fromFirestore(doc)).toList());
  }

  // Regar Planta (Atualiza a data para AGORA)
  Future<void> waterPlant(String plantId) async {
    await _db.collection('plants').doc(plantId).update({
      'lastWatered': FieldValue.serverTimestamp(),
      'wateringHistory': FieldValue.arrayUnion([Timestamp.now()])
    });
  }

  // Apagar Planta
  Future<void> deletePlant(String plantId) async {
    await _db.collection('plants').doc(plantId).delete();
  }
  Future<void> addRoom(String name, String lightLevel, bool isExterior) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('rooms').add({
      'userId': user.uid,
      'name': name,
      'lightLevel': lightLevel,
      'isExterior': isExterior,
    });
  }
  Stream<List<Room>> getUserRooms() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('rooms')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Room(
                name: data['name'] ?? '',
                lightLevel: data['lightLevel'] ?? '',
                isExterior: data['isExterior'] ?? false,
              );
            }).toList());
  }
  
}