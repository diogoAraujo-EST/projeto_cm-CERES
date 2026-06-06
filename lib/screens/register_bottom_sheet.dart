import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

class RegisterBottomSheet extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterBottomSheet({super.key, required this.onSwitchToLogin});

  @override
  State<RegisterBottomSheet> createState() => _RegisterBottomSheetState();
}

class _RegisterBottomSheetState extends State<RegisterBottomSheet> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;

    if (name.isEmpty) {
      setState(() => _nameError = 'Por favor, introduza o seu nome');
      hasError = true;
    } else if (name.length > 20) {
      setState(() => _nameError = 'O nome não pode ter mais de 20 caracteres');
      hasError = true;
    }
    
    if (email.isEmpty) {
      setState(() => _emailError = 'Por favor, introduza o seu email');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Por favor, defina uma password');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'A password deve ter pelo menos 6 caracteres');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      // Passa o nome para o AuthService
      await _authService.registerWithEmailAndPassword(email, password, name);
      if (mounted) {
        Navigator.pop(context);
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
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
      setState(() => _passwordError = 'Erro ao registar a conta.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

            // Campo Nome com limite de 20 caracteres nativo
            TextField(
              controller: _nameController,
              maxLength: 20, // Bloqueia automaticamente a digitação a partir de 20 caracteres
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                hintText: 'Nome',
                errorText: _nameError,
                counterText: "", // Esconde o contador numérico nativo para manter o design limpo
                prefixIcon: const Icon(Icons.person_outline, color: CERESColors.textSecondary),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 12),

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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tens conta? ', style: TextStyle(color: CERESColors.textSecondary)),
                GestureDetector(
                  onTap: widget.onSwitchToLogin,
                  child: const Text('Inicia sessão', style: TextStyle(color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),

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