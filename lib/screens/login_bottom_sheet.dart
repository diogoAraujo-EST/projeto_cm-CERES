import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'forgot_password_bottom_sheet.dart';

// Mais uma vez, isto é um BottomSheet (aquelas abas que sobem de baixo).
// Não é um ecrã inteiro (Screen).
class LoginBottomSheet extends StatefulWidget {
  // O menu pai (LoginScreen) envia-nos esta função para sabermos o que fazer 
  // caso o utilizador decida clicar em "Regista-te agora".
  final VoidCallback onSwitchToRegister;

  const LoginBottomSheet({super.key, required this.onSwitchToRegister});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  // Controlos da interface
  bool _obscurePassword = true; // Mostra as bolinhas em vez da password
  bool _isLoading = false;      // Roda o loading no botão de entrar

  // Controladores das caixas de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // A nossa ligação principal ao Firebase Auth
  final _authService = AuthService();

  // Guardamos os textos de erro diretamente aqui para pintarmos 
  // as caixas de texto de vermelho em caso de falha.
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    // Limpar os controladores quando o menu fecha
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- NAVEGAÇÃO ENTRE MENUS ---
  // Acontece quando o utilizador clica em "Esqueceste a password?"
  void _showForgotPasswordSheet() {
    Navigator.pop(context); // 1. Fecha ESTE menu de Login primeiro para não encavalar
    
    // 2. Abre o menu da recuperação de password
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Importante para o teclado não comer o menu
      backgroundColor: Colors.transparent,
      builder: (context) => ForgotPasswordBottomSheet(
        // E o que acontece quando clica no "Voltar para o Login"? 
        // Fazemos o percurso inverso!
        onBackToLogin: () {
          Navigator.pop(context); // Fecha a recuperação
          // Reabre o login de forma limpa, passando a função de registo de volta
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => LoginBottomSheet(onSwitchToRegister: widget.onSwitchToRegister),
          );
        },
      ),
    );
  }

  // --- LOGIN TRADICIONAL (Email e Password) ---
  Future<void> _login() async {
    // 1. Limpa erros antigos
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;

    // 2. Verifica se ele se esqueceu de escrever alguma coisa
    if (email.isEmpty) {
      setState(() => _emailError = 'Por favor, introduza o seu email');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Por favor, introduza a sua password');
      hasError = true;
    }

    // Se houve erro de campos vazios, aborta já
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      // 3. Pede ao AuthService para tentar o Login no Firebase
      await _authService.signInWithEmailAndPassword(email, password);
      
      if (mounted) {
        Navigator.pop(context); // Esconde a aba de login
        context.go('/home');    // Vai de viagem para o ecrã inicial!
      }
    } on FirebaseAuthException catch (e) {
      // 4. Se falhou, vamos perceber porquê e pintar a caixa de texto certa de vermelho
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          _emailError = 'Este email não está registado';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _passwordError = 'A password introduzida está incorreta';
        } else {
          _passwordError = 'Erro ao iniciar sessão. Tente novamente.';
        }
      });
    } catch (e) {
      // Falha geral (falta de net, servidores da google em baixo, etc)
      setState(() => _passwordError = 'Ocorreu um erro inesperado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIN COM A GOOGLE ---
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      // O utilizador pode cancelar a meio (ex: fechar a janelinha do Google). 
      // Só avançamos se a variável user não for nula!
      if (user != null && mounted) {
        Navigator.pop(context);
        context.go('/home');
      }
    } catch (e) {
      _showSnackBar('Erro de ligação com a conta Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIN COMO CONVIDADO (Anónimo) ---
  // Ideal para pessoas que querem apenas testar a app antes de dar os seus dados
  Future<void> _loginAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInAnonymously();
      if (mounted) {
        Navigator.pop(context);
        context.go('/home');
      }
    } catch (e) {
      _showSnackBar('Erro ao entrar como convidado.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Atalho visual para mensagens de erro curtas
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Tal como no ecrã de recuperação de password, calculamos a altura do teclado do telemóvel 
    // e adicionamos ao padding debaixo (bottom) para o menu subir com o teclado.
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24 + keyboardPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Não deixar que a aba seja gigante se não tiver conteúdo
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // O tracinho do topo para o efeito visual de gaveta
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Bem-vindo de volta! 🌿',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CERESColors.textMain),
            ),
            const SizedBox(height: 20),

            // --- CAIXA DE EMAIL ---
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                // Truque de UX: se estava vermelho com erro, apaga o erro assim que a pessoa volta a escrever
                if (_emailError != null) setState(() => _emailError = null);
              },
              decoration: InputDecoration(
                hintText: 'Email',
                errorText: _emailError, // Vai pintar de vermelho se tiver erro
                prefixIcon: const Icon(Icons.email_outlined, color: CERESColors.textSecondary),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 12),

            // --- CAIXA DE PASSWORD ---
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword, // Oculatar ou mostrar texto
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
              decoration: InputDecoration(
                hintText: 'Password',
                errorText: _passwordError,
                prefixIcon: const Icon(Icons.lock_outline, color: CERESColors.textSecondary),
                // Botão em forma de olho para alternar a visibilidade da password
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: CERESColors.textSecondary),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
              ),
            ),

            // --- ESQUECEU A PASSWORD ---
            Align(
              alignment: Alignment.centerRight, // Encostar este pequeno botão à direita
              child: TextButton(
                onPressed: _showForgotPasswordSheet,
                child: const Text('Esqueceste a password?', style: TextStyle(color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),

            // --- BOTÃO DE ENTRAR PRINCIPAL ---
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: CERESColors.primaryDarkGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Entrar', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            // --- LINK PARA REGISTO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ainda não tens conta? ', style: TextStyle(color: CERESColors.textSecondary)),
                GestureDetector(
                  onTap: widget.onSwitchToRegister, // Chama a função que fecha este menu e abre o menu de Registo
                  child: const Text('Regista-te agora', style: TextStyle(color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- DIVISÓRIA ( --- ou --- ) ---
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)), // Traço esquerdo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ou', style: TextStyle(color: Colors.grey.shade400)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)), // Traço direito
              ],
            ),
            const SizedBox(height: 24),

            // --- BOTÃO DO GOOGLE ---
            OutlinedButton(
              onPressed: _isLoading ? null : _loginWithGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: Colors.grey.shade300), // Bordas cinzentas limpas
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Usa um link público da Wikipedia para o Logo da Google para não pesar a app com mais imagens
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                    height: 20,
                    // Se estiver sem net na altura em que isto renderiza, cai graciosamente num ícone feio mas funcional
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Continuar com o Google', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- ENTRAR COMO CONVIDADO ---
            TextButton(
              onPressed: _isLoading ? null : _loginAsGuest,
              child: const Text('Continuar como Convidado', style: TextStyle(color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}