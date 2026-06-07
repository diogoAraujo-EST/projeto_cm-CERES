import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/room.dart';
import '../models/user_plant.dart';

// O nosso serviço principal de comunicação com a Base de Dados (Firestore) e Armazenamento (Storage)
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Base de Dados de Texto
  final FirebaseAuth _auth = FirebaseAuth.instance;         // Segurança
  final FirebaseStorage _storage = FirebaseStorage.instance;// Armazém de Ficheiros (Fotos)

  // ---------------------------------------------------------------------------
  // GESTÃO DE UTILIZADORES
  // ---------------------------------------------------------------------------
  
  // Chamada sempre que alguém faz um registo (quer seja email, google, ou convidado)
  Future<void> createUserDocument(User user, {String? name}) async {
    // Aponta para a pasta "users" e procura o documento com o ID deste utilizador
    final userRef = _db.collection('users').doc(user.uid);
    final doc = await userRef.get();

    // Se ele ainda não tiver um documento criado, cria agora!
    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'name': name ?? user.displayName ?? 'Utilizador', // Ordem de prioridade de nomes
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(), // Marca a data exata do servidor
      });
    }
  }

  // O "Tubo" em tempo real que o ecrã do Perfil fica a ouvir
  Stream<DocumentSnapshot> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilizador não autenticado");
    
    // .snapshots() é o que cria a magia do "Tempo Real"
    return _db.collection('users').doc(user.uid).snapshots();
  }

  // Upload do Avatar
  Future<void> uploadProfilePicture(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilizador não autenticado");

    try {
      // Descobre se é um .png ou .jpg
      final ext = imageFile.path.split('.').last;
      
      // Constrói o caminho da pasta: users -> ID -> profile -> ficheiro
      // Usamos a data (millisecondsSinceEpoch) para o nome da foto não bater num antigo e bugar o cache!
      final storageRef = _storage.ref().child('users/${user.uid}/profile/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext');
      
      // Envia fisicamente o ficheiro pesado para a nuvem
      await storageRef.putFile(imageFile);
      
      // Agora pedimos à nuvem um link público para podermos mostrar na app
      final downloadUrl = await storageRef.getDownloadURL();

      // Guarda o link na pasta de texto deste utilizador
      await _db.collection('users').doc(user.uid).update({'photoUrl': downloadUrl});
      
      // E guarda também no sistema rápido de Autenticação
      await user.updatePhotoURL(downloadUrl);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // GESTÃO DE PLANTAS
  // ---------------------------------------------------------------------------

  // Onde a planta ganha vida na nuvem!
  Future<void> addPlant(UserPlant plant, {File? imageFile}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Aponta para a pasta "plants" deste utilizador, mas deixa os parêntesis .doc() vazios
    // Isto diz ao Firebase: "Por favor, inventa um ID aleatório seguro para mim".
    final docRef = _db.collection('users').doc(user.uid).collection('plants').doc();
    
    // Por defeito, usamos a foto standard que veio da API de Espécies
    String finalImageUrl = plant.imageUrl; 

    // 2. MAS, se ele tirou uma foto real na hora...
    if (imageFile != null) {
      final ext = imageFile.path.split('.').last;
      // Mandamos para a pasta da planta e guardamos usando o ID aleatório gerado acima
      final storageRef = _storage.ref().child('users/${user.uid}/plants/${docRef.id}/photo_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await storageRef.putFile(imageFile);
      // E trocamos o link da API pelo link da foto real!
      finalImageUrl = await storageRef.getDownloadURL();
    }

    // 3. Prepara a "caixa" com a informação para enviar para os servidores de texto
    final plantMap = plant.toMap();
    plantMap['imageUrl'] = finalImageUrl;

    // 4. Guarda tudo no Firestore com o tal ID aleatório gerado!
    await docRef.set(plantMap);
  }

  // Quando o utilizador clica sem querer na foto errada e quer trocar
  Future<String> updatePlantImage(String plantId, File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Utilizador não autenticado");

    final ext = imageFile.path.split('.').last;
    final storageRef = _storage.ref().child('users/${user.uid}/plants/$plantId/photo_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await storageRef.putFile(imageFile);
    final downloadUrl = await storageRef.getDownloadURL();

    // Atualiza APENAS o campo "imageUrl" dentro da pasta desta planta
    await _db.collection('users').doc(user.uid).collection('plants').doc(plantId).update({
      'imageUrl': downloadUrl,
    });

    // Devolvemos a String do link para a imagem piscar e atualizar logo no ecrã do utilizador
    return downloadUrl; 
  }

  // O motor dos HomeScreens e Lists: "Dá-me todas as plantas que este gajo tem!"
  Stream<List<UserPlant>> getUserPlants() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]); // Retorna uma lista vazia pacífica se não houver user

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('plants')
        .snapshots() // Ouve as alterações do Firebase sempre que algo muda (Tempo real!)
        // O "map" traduz a linguagem estranha de documentos do Firebase para a nossa linguagem 
        // Dart limpa (UserPlant), um por um.
        .map((snapshot) => snapshot.docs.map((doc) => UserPlant.fromFirestore(doc)).toList());
  }

  // Acção Rápida: Dar de beber!
  Future<void> waterPlant(String plantId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).collection('plants').doc(plantId).update({
      // 1. Atualiza a data da última rega para AGORA
      'lastWatered': FieldValue.serverTimestamp(),
      // 2. arrayUnion pega no Histórico inteiro e empurra uma nova data lá para dentro.
      // (É isto que depois permite aos gráficos das Estatísticas funcionarem!!)
      'wateringHistory': FieldValue.arrayUnion([Timestamp.now()])
    });
  }

  // Mandar uma planta desta para melhor
  Future<void> deletePlant(String plantId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    // Basta apontar a arma ao documento e premir o gatilho (.delete())
    await _db.collection('users').doc(user.uid).collection('plants').doc(plantId).delete();
  }

  // ---------------------------------------------------------------------------
  // GESTÃO DE DIVISÕES (Quartos, Varandas, Escritórios)
  // ---------------------------------------------------------------------------
  
  // Criar uma zona nova na casa
  Future<void> addRoom(String name, String lightLevel, bool isExterior) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // .add() é outra forma de gerar um ID aleatório à pressa e guardar logo lá dentro
    await _db.collection('users').doc(user.uid).collection('rooms').add({
      'name': name,
      'lightLevel': lightLevel,
      'isExterior': isExterior,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Vai buscar as divisões do utilizador (usado quando crias a planta para preencher os "botõezinhos/chips" de escolha)
  Stream<List<Room>> getUserRooms() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('rooms')
        .orderBy('createdAt') // Garante que a divisão mais antiga aparece primeiro (A ordem da casa não muda do nada)
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