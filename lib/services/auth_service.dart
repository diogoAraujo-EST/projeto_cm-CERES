import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. Registo com Email/Password
  // 1. Registo com Email/Password e gravação do Nome
  Future<User?> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualiza o perfil do utilizador com o nome introduzido
      await result.user?.updateDisplayName(name);
      
      // Força o Firebase a recarregar os dados atualizados
      await result.user?.reload();
      
      return _auth.currentUser;
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

  // 3. Entrar como Convidado (Autenticação Anónima do Firebase)
  // Isto gera um utilizador temporário, o que permite que a regra do GoRouter funcione sem alterações!
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // 4. Entrar com o Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Utilizador cancelou o processo

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // 5. Enviar email de recuperação de palavra-passe
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