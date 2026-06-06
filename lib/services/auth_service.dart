import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService(); // Instância do FirestoreService

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. Registo com Email/Password e gravação do Nome
  Future<User?> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualiza o auth profile
      await result.user?.updateDisplayName(name);
      await result.user?.reload();
      
      final updatedUser = _auth.currentUser;
      if (updatedUser != null) {
        // LIGAÇÃO AO FIRESTORE: Cria a pasta do utilizador!
        await _firestoreService.createUserDocument(updatedUser, name: name);
      }
      
      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }

  // 2. Login com Email/Password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // 3. Entrar como Convidado
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      if (result.user != null) {
        // LIGAÇÃO AO FIRESTORE: Cria pasta para o convidado
        await _firestoreService.createUserDocument(result.user!, name: 'Convidado');
      }
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // 4. Entrar com o Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // LIGAÇÃO AO FIRESTORE: Cria/Atualiza pasta para user Google
        await _firestoreService.createUserDocument(result.user!);
      }
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // 5. Enviar email de recuperação
  Future<void> sendPasswordReset(String email) async {
   try {
     await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
    rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}