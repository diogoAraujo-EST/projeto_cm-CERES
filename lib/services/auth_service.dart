import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

// O nosso serviço dedicado a gerir identidades e acessos
class AuthService {
  // A linha direta para o departamento de segurança do Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Instância da base de dados para podermos criar as "pastas" dos novos utilizadores
  final FirestoreService _firestoreService = FirestoreService(); 

  // Atalhos práticos para os outros ecrãs saberem quem está logado neste momento
  User? get currentUser => _auth.currentUser;
  
  // Isto é uma "escuta ativa". O main.dart ou outros ficheiros podem ficar a ouvir isto 
  // para saberem instantaneamente se a pessoa fez logout e mandá-la para a rua.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- 1. REGISTO TRADICIONAL (Email/Password) ---
  Future<User?> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      // Passo 1: O Firebase cria o utilizador apenas com email e password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Passo 2: O Firebase não deixa passar o nome no ato da criação.
      // Por isso, fazemos "update" ao perfil logo a seguir com o nome que o utilizador escolheu.
      await result.user?.updateDisplayName(name);
      await result.user?.reload(); // Atualiza a "cache" interna
      
      final updatedUser = _auth.currentUser;
      if (updatedUser != null) {
        // Passo 3 (O mais importante!): Cria a gaveta deste utilizador na base de dados real (Firestore),
        // senão ele não tinha onde guardar as plantas mais tarde!
        await _firestoreService.createUserDocument(updatedUser, name: name);
      }
      
      return updatedUser;
    } catch (e) {
      // Usamos rethrow para atirar a "batata quente" (o erro) de volta para o ecrã de Registo.
      // É lá que os erros são traduzidos (ex: "Email já em uso") e pintam as caixas de texto de vermelho.
      rethrow;
    }
  }

  // --- 2. LOGIN TRADICIONAL ---
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Simples e direto: tenta entrar, se as chaves servirem, devolve o utilizador.
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // --- 3. ENTRAR COMO CONVIDADO (Anónimo) ---
  // Ideal para baixar as barreiras de entrada. O utilizador testa a app sem compromisso.
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      if (result.user != null) {
        // Mesmo sendo um convidado (conta fantasma), ele precisa de uma pasta na base de dados!
        await _firestoreService.createUserDocument(result.user!, name: 'Convidado');
      }
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // --- 4. LOGIN COM O GOOGLE ---
  Future<User?> signInWithGoogle() async {
    try {
      // Passo 1: Abre a janelinha do sistema operativo para a pessoa escolher a sua conta Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      // Se a pessoa carregou fora da caixa e cancelou, abortamos pacificamente
      if (googleUser == null) return null;

      // Passo 2: Pede ao Google os bilhetes de autenticação (Tokens)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Passo 3: Entrega os bilhetes do Google ao Firebase. O Firebase verifica e deixa entrar.
      UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // Passo 4: Como pode ser a primeira vez que ele entra com o Google, 
        // mandamos criar ou atualizar a pasta dele na base de dados!
        await _firestoreService.createUserDocument(result.user!);
      }
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // --- 5. RECUPERAÇÃO DE PASSWORD ---
  Future<void> sendPasswordReset(String email) async {
   try {
     // Um pedido simples ao Firebase para enviar o email automático que configuraste na consola deles
     await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // --- 6. LOGOUT ---
  Future<void> signOut() async {
    // Rasga os bilhetes de autenticação locais e fecha a sessão
    await _auth.signOut();
  }
}