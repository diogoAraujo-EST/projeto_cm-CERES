import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/room.dart';
import '../models/user_plant.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // GESTÃO DE UTILIZADORES
  // ---------------------------------------------------------------------------
  Future<void> createUserDocument(User user, {String? name}) async {
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'name': name ?? user.displayName ?? 'Utilizador',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<DocumentSnapshot> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilizador não autenticado");
    return _db.collection('users').doc(user.uid).snapshots();
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilizador não autenticado");

    try {
      final ext = imageFile.path.split('.').last;
      final storageRef = _storage.ref().child('users/${user.uid}/profile/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      await _db.collection('users').doc(user.uid).update({'photoUrl': downloadUrl});
      await user.updatePhotoURL(downloadUrl);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // GESTÃO DE PLANTAS
  // ---------------------------------------------------------------------------

  // Atualizado: Agora recebe um File opcional para a imagem tirada pelo utilizador
  Future<void> addPlant(UserPlant plant, {File? imageFile}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Gera um ID único e uma referência de documento vazia primeiro
    final docRef = _db.collection('users').doc(user.uid).collection('plants').doc();
    
    String finalImageUrl = plant.imageUrl; // Default vindo da API

    // 2. Se o utilizador tirou uma foto, faz upload para o Storage na pasta da Planta
    if (imageFile != null) {
      final ext = imageFile.path.split('.').last;
      final storageRef = _storage.ref().child('users/${user.uid}/plants/${docRef.id}/photo_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await storageRef.putFile(imageFile);
      finalImageUrl = await storageRef.getDownloadURL();
    }

    // 3. Atualiza o mapa com a imagem real (seja da API ou da Câmara)
    final plantMap = plant.toMap();
    plantMap['imageUrl'] = finalImageUrl;

    // 4. Guarda no Firestore com o ID que gerámos
    await docRef.set(plantMap);
  }

  // Novo: Atualizar apenas a foto da planta existente
  Future<String> updatePlantImage(String plantId, File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilizador não autenticado");

    final ext = imageFile.path.split('.').last;
    final storageRef = _storage.ref().child('users/${user.uid}/plants/$plantId/photo_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await storageRef.putFile(imageFile);
    final downloadUrl = await storageRef.getDownloadURL();

    await _db.collection('users').doc(user.uid).collection('plants').doc(plantId).update({
      'imageUrl': downloadUrl,
    });

    return downloadUrl; // Devolvemos o URL para o ecrã atualizar de imediato
  }

  Stream<List<UserPlant>> getUserPlants() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]); 

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('plants')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserPlant.fromFirestore(doc)).toList());
  }

  Future<void> waterPlant(String plantId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).collection('plants').doc(plantId).update({
      'lastWatered': FieldValue.serverTimestamp(),
      'wateringHistory': FieldValue.arrayUnion([Timestamp.now()])
    });
  }

  Future<void> deletePlant(String plantId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).collection('plants').doc(plantId).delete();
  }

  // ---------------------------------------------------------------------------
  // GESTÃO DE DIVISÕES
  // ---------------------------------------------------------------------------
  Future<void> addRoom(String name, String lightLevel, bool isExterior) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).collection('rooms').add({
      'name': name,
      'lightLevel': lightLevel,
      'isExterior': isExterior,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Room>> getUserRooms() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('rooms')
        .orderBy('createdAt')
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