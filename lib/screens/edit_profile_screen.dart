import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Verifica se o utilizador fez login com Email/Password (Google Auth não pode mudar password assim)
  bool _isEmailAuth = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null) {
        _nameController.text = user.displayName!;
      }
      // Verifica na lista de provedores se usou 'password'
      _isEmailAuth = user.providerData.any((provider) => provider.providerId == 'password');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newName.isEmpty) {
      _showError('O nome não pode estar vazio.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. TENTA ATUALIZAR A PASSWORD SE OS CAMPOS FOREM PREENCHIDOS
      if (oldPass.isNotEmpty || newPass.isNotEmpty || confirmPass.isNotEmpty) {
        if (oldPass.isEmpty) {
          _showError('Insere a tua password atual para confirmar a alteração.');
          setState(() => _isLoading = false);
          return;
        }
        if (newPass.length < 6) {
          _showError('A nova password deve ter pelo menos 6 caracteres.');
          setState(() => _isLoading = false);
          return;
        }
        if (newPass != confirmPass) {
          _showError('A nova password e a confirmação não coincidem!');
          setState(() => _isLoading = false);
          return;
        }

        // --- REAUTENTICAÇÃO NO FIREBASE ---
        try {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!, 
            password: oldPass
          );
          
          // Revalida a password antiga
          await user.reauthenticateWithCredential(credential);
          
          // Se não der erro, atualiza para a nova
          await user.updatePassword(newPass);
          
        } on FirebaseAuthException catch (e) {
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            _showError('A password atual está incorreta.');
          } else {
            _showError('Erro ao validar a password. Tenta novamente.');
          }
          setState(() => _isLoading = false);
          return; // Aborta aqui, não guarda nada!
        }
      }

      // 2. ATUALIZA O NOME 
      if (user.displayName != newName) {
        await user.updateDisplayName(newName);
        await user.reload(); // Força a Firebase a atualizar a cache
      }

      // SUCESSO TOTAL
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: CERESColors.primaryDarkGreen),
        );
        context.pop(); 
      }
      
    } catch (e) {
      if (mounted) _showError('Ocorreu um erro ao atualizar o perfil.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Widget auxiliar para as caixas da password
  Widget _buildPasswordField(String hint, TextEditingController controller, bool obscureValue, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscureValue,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, color: CERESColors.textSecondary),
        suffixIcon: IconButton(
          icon: Icon(obscureValue ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: CERESColors.textSecondary),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
        title: const Text('Editar Perfil', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      body: isGuest 
        ? const Center(child: Text('Contas de convidado não podem ser editadas.', style: TextStyle(color: CERESColors.textSecondary)))
        : SingleChildScrollView( // Mudou para SingleChildScrollView para o teclado não tapar
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nome de Apresentação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: 'O teu nome',
                    prefixIcon: const Icon(Icons.person_outline, color: CERESColors.textSecondary),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
                  ),
                ),
                
                // SÓ MOSTRA SE FOR UMA CONTA COM EMAIL/PASSWORD
                if (_isEmailAuth) ...[
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),
                  
                  const Text('Alterar Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 4),
                  const Text('Deixa em branco se não quiseres alterar.', style: TextStyle(fontSize: 13, color: CERESColors.textSecondary)),
                  const SizedBox(height: 16),
                  
                  _buildPasswordField('Password Atual', _oldPasswordController, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
                  const SizedBox(height: 12),
                  _buildPasswordField('Nova Password', _newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 12),
                  _buildPasswordField('Confirmar Nova Password', _confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                ],

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CERESColors.primaryDarkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar Alterações', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40), // Espaço extra em baixo para o scroll
              ],
            ),
          ),
    );
  }
}