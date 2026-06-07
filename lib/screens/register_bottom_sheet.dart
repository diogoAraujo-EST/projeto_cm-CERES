import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

// O menu de registo também é um BottomSheet (aquela aba que sobe) 
// para manter a consistência com a experiência de Login.
class RegisterBottomSheet extends StatefulWidget {
  // Função enviada pela página principal (WelcomeScreen) para sabermos como 
  // saltar daqui para a aba de Login, caso a pessoa clique em "Já tens conta?".
  final VoidCallback onSwitchToLogin;

  const RegisterBottomSheet({super.key, required this.onSwitchToLogin});

  @override
  State<RegisterBottomSheet> createState() => _RegisterBottomSheetState();
}

class _RegisterBottomSheetState extends State<RegisterBottomSheet> {
  // Controlos visuais
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Ao contrário do login, aqui temos 3 campos: precisamos do nome também!
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _authService = AuthService();

  // Guardar os erros individuais para pintar apenas as caixas que estiverem mal
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    // A clássica limpeza de primavera
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE REGISTO ---
  Future<void> _register() async {
    // 1. Apagar erros do ecrã antes de testar
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;

    // 2. VALIDAÇÕES LOCAIS (Para não gastar internet a perguntar ao Firebase se o nome pode estar vazio)
    if (name.isEmpty) {
      setState(() => _nameError = 'Por favor, introduza o seu nome');
      hasError = true;
    } else if (name.length > 20) {
      // Bloqueio extra de segurança, embora o TextField já limite a escrita nativamente
      setState(() => _nameError = 'O nome não pode ter mais de 20 caracteres');
      hasError = true;
    }
    
    if (email.isEmpty) {
      setState(() => _emailError = 'Por favor, introduza o seu email');
      hasError = true;
    }
    
    // O Firebase obriga a que a password tenha pelo menos 6 caracteres!
    if (password.isEmpty) {
      setState(() => _passwordError = 'Por favor, defina uma password');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'A password deve ter pelo menos 6 caracteres');
      hasError = true;
    }

    // Se a app encontrou algum erro na verificação acima, pára logo por aqui
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      // 3. Manda o serviço criar a conta lá na Cloud
      // Nota que passamos o "name" também! O serviço vai criar a conta e depois atualizar o perfil com esse nome.
      await _authService.registerWithEmailAndPassword(email, password, name);
      
      if (mounted) {
        Navigator.pop(context); // Fecha esta aba
        context.go('/home'); // Entra na App!
      }
    } on FirebaseAuthException catch (e) {
      // 4. Se o Firebase recusar o registo, apanhamos o erro aqui
      setState(() {
        if (e.code == 'email-already-in-use') {
          _emailError = 'Este email já se encontra em utilização';
        } else if (e.code == 'invalid-email') {
          _emailError = 'O email introduzido não é válido';
        } else {
          _passwordError = 'Erro ao registar a conta. Tente novamente.';
        }
      });
    } catch (e) {
      // Erro desconhecido/sem internet
      setState(() => _passwordError = 'Erro ao registar a conta.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- REGISTO COM GOOGLE ---
  // É igualzinho ao login com google. Se a conta não existir, a google cria-a na hora e o utilizador entra.
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
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

  // --- CONTA DE CONVIDADO ---
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos o padding do teclado para a gaveta deslizar para cima em vez de ficar por trás das teclas
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24 + keyboardPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // O tracinho estético no topo da gaveta
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Criar Conta 🌿',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CERESColors.textMain),
            ),
            const SizedBox(height: 20),

            // --- CAMPO NOME ---
            TextField(
              controller: _nameController,
              // O Flutter corta logo a digitação se o utilizador tentar passar dos 20 caracteres
              maxLength: 20, 
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                hintText: 'Nome',
                errorText: _nameError,
                counterText: "", // Esconde o contador "0/20" que aparece por baixo da caixa
                prefixIcon: const Icon(Icons.person_outline, color: CERESColors.textSecondary),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 12),

            // --- CAMPO EMAIL ---
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              decoration: InputDecoration(
                hintText: 'Email',
                errorText: _emailError,
                prefixIcon: const Icon(Icons.email_outlined, color: CERESColors.textSecondary),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 12),

            // --- CAMPO PASSWORD ---
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
              decoration: InputDecoration(
                hintText: 'Password',
                errorText: _passwordError,
                prefixIcon: const Icon(Icons.lock_outline, color: CERESColors.textSecondary),
                // Botão em forma de olho para ver a password
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
            const SizedBox(height: 24),

            // --- BOTÃO DE REGISTAR ---
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: CERESColors.primaryDarkGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Criar Conta', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            // --- LINK PARA VOLTAR AO LOGIN ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tens conta? ', style: TextStyle(color: CERESColors.textSecondary)),
                GestureDetector(
                  // A tal função que recebemos no topo do ecrã
                  onTap: widget.onSwitchToLogin,
                  child: const Text('Inicia sessão', style: TextStyle(color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Divisória ( --- ou --- )
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ou', style: TextStyle(color: Colors.grey.shade400)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 24),

            // --- REGISTAR COM GOOGLE ---
            OutlinedButton(
              onPressed: _isLoading ? null : _loginWithGoogle,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('Registar com o Google', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
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