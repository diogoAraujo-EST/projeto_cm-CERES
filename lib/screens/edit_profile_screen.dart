import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controladores de texto para ler o que o utilizador digita
  final _nameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final FirestoreService _firestoreService = FirestoreService();

  // Controlos de UI e visibilidade
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  // Flag para esconder a secção da password se o utilizador tiver feito login com o Google
  bool _isEmailAuth = false;

  @override
  void initState() {
    super.initState();
    // 1. Assim que a janela abre, tentamos descarregar o nome real do utilizador da nossa BD
    _loadProtectedName();
    
    // 2. Verificamos que tipo de conta ele tem (Google vs Email/Pass)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isEmailAuth = user.providerData.any((provider) => provider.providerId == 'password');
    }
  }

  // --- LÊ O NOME DA BASE DE DADOS (Não do Auth!) ---
  // O truque de mestre deste ecrã: O Auth da Google tenta sempre injetar o nome completo da pessoa
  // na App. Nós ignoramos isso e vamos buscar o nome (mesmo que seja um apelido) que a 
  // pessoa guardou manualmente na nossa base de dados (Firestore).
  Future<void> _loadProtectedName() async {
    final name = await _firestoreService.getUserName(); // Chama o teu novo método inteligente!
    
    // Se a internet falhar a meio disto, o ecrã não crasha porque usamos o "mounted"
    // para garantir que a janela ainda não foi fechada.
    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _nameController.text = name;
      });
    } else {
      // Fallback seguro se a BD falhar (Usa o que estiver em cache no aparelho)
      final user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null && mounted) {
        setState(() => _nameController.text = user!.displayName!);
      }
    }
  }

  @override
  void dispose() {
    // Limpeza de memória obrigatória quando o ecrã fecha
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Atalho para não escrever o código dos SnackBars (Avisos) vezes sem conta
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  // --- FUNÇÃO PRINCIPAL DE GRAVAÇÃO ---
  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    // Proteção da Base de dados (Sanitization): Não deixar enviar nomes vazios
    if (newName.isEmpty) {
      _showError('O nome não pode estar vazio.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. TENTA ATUALIZAR A PASSWORD
      // Só entra neste bloco gigante se a pessoa tiver tocado numa das 3 caixas de password
      if (oldPass.isNotEmpty || newPass.isNotEmpty || confirmPass.isNotEmpty) {
        
        // Bloqueios de segurança locais para poupar pedidos à Cloud
        if (oldPass.isEmpty) return _showError('Insere a tua password atual.');
        if (newPass.length < 6) return _showError('A nova password deve ter pelo menos 6 caracteres.');
        if (newPass != confirmPass) return _showError('A nova password e a confirmação não coincidem!');

        try {
          // O Firebase obriga a pessoa a fazer um "login fantasma" aqui para provar
          // que não é alguém que apanhou o telemóvel desbloqueado em cima da mesa.
          AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPass);
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(newPass);
          
        } on FirebaseAuthException catch (e) {
          // Catch específico de falha na autenticação (Pass antiga errada)
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            _showError('A password atual está incorreta.');
          } else {
            _showError('Erro ao validar a password. Tenta novamente.');
          }
          setState(() => _isLoading = false);
          return; // Aborta! Não guarda o nome se a password falhou.
        }
      }

      // 2. ATUALIZA O NOME APENAS NA BASE DE DADOS SEGURA!
      // Chamamos aquele teu novo método espetacular que tem o SetOptions(merge: true)
      await _firestoreService.saveUserProfile(newName);

      // Sucesso Total!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: CERESColors.primaryDarkGreen),
        );
        context.pop(); // Volta à página principal do Perfil
      }
      
    } catch (e) {
      if (mounted) _showError('Ocorreu um erro ao atualizar o perfil.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGET AJUDANTE (Construtor de Caixas de Texto) ---
  // Como as 3 caixas de password têm 99% do design igual, metemos isto numa função.
  // Fica muito mais fácil de ler o método build lá em baixo!
  Widget _buildPasswordField(String hint, TextEditingController controller, bool obscureValue, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: obscureValue,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, color: CERESColors.textSecondary),
        suffixIcon: IconButton(
          // Muda o ícone entre o olho aberto e fechado
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
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
        title: const Text('Editar Perfil', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      
      // Bloqueio de Convidado: Se ele está a testar a app, não faz sentido ter Perfil
      body: isGuest 
        ? const Center(child: Text('Contas de convidado não podem ser editadas.', style: TextStyle(color: CERESColors.textSecondary)))
        // O SingleChildScrollView garante que o ecrã empurra as coisas para cima quando o teclado abre
        : SingleChildScrollView( 
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- ÁREA DO NOME ---
                const Text('Nome de Apresentação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    counterText: "", hintText: 'O teu nome',
                    prefixIcon: const Icon(Icons.person_outline, color: CERESColors.textSecondary),
                    filled: true, fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
                  ),
                ),
                
                // --- ÁREA DA PASSWORD ---
                // Esta secção TODA só é desenhada se a pessoa NÃO tiver usado o Google Sign in.
                if (_isEmailAuth) ...[
                  const SizedBox(height: 32), const Divider(color: Color(0xFFEEEEEE)), const SizedBox(height: 24),
                  const Text('Alterar Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 4),
                  const Text('Deixa em branco se não quiseres alterar.', style: TextStyle(fontSize: 13, color: CERESColors.textSecondary)),
                  const SizedBox(height: 16),
                  
                  // Chamamos o nosso ajudante 3 vezes seguidas! Fica muito mais limpo.
                  _buildPasswordField('Password Atual', _oldPasswordController, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
                  const SizedBox(height: 12),
                  _buildPasswordField('Nova Password', _newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 12),
                  _buildPasswordField('Confirmar Nova Password', _confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                ],

                const SizedBox(height: 40),
                
                // --- BOTÃO DE GUARDAR ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: CERESColors.primaryDarkGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    // Se estiver a pensar (loading), o texto desaparece e entra uma rodinha
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar Alterações', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40), 
              ],
            ),
          ),
    );
  }
}