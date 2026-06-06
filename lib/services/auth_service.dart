import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obter o utilizador atualmente autenticado
  User? get currentUser => _auth.currentUser;

  // Stream que notifica mudanças no estado da autenticação (login/logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Criar conta com Email e Password
  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      rethrow; // Reencaminha o erro para ser tratado no ecrã (UI)
    }
  }

  // Iniciar sessão com Email e Password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // Terminar Sessão (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}