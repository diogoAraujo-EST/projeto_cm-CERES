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
  // Os nossos controladores para ler o que o utilizador escreve nas caixas de texto
  final _nameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controlos da interface (UI)
  bool _isLoading = false; // Para a rodinha no botão de guardar
  
  // Para sabermos se mostramos as bolinhas pretas ou o texto limpo nas passwords (o ícone do olho)
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ESTA VARIÁVEL É SUPER IMPORTANTE!
  // Se o utilizador fez login com o Google, a password dele é gerida pela Google e não pelo Firebase.
  // Usamos isto para esconder a secção de "Mudar Password" caso não seja uma conta de Email/Password.
  bool _isEmailAuth = false;

  @override
  void initState() {
    super.initState();
    // Assim que abrimos o ecrã, vamos buscar os dados atuais para pré-preencher os campos
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Mete o nome atual na caixa de texto
      if (user.displayName != null) {
        _nameController.text = user.displayName!;
      }
      // Aqui vasculhamos os "providers" do utilizador. 
      // Se encontrarmos 'password', significa que ele se registou da forma tradicional.
      _isEmailAuth = user.providerData.any((provider) => provider.providerId == 'password');
    }
  }

  @override
  void dispose() {
    // Boas práticas do Flutter: Limpar os controladores da memória quando fechamos o ecrã
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Um atalho rápido para mostrar a barra vermelha de erro lá em baixo
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- O CÉREBRO DESTE ECRÃ ---
  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    // Proteção básica 1: Um nome tem de existir
    if (newName.isEmpty) {
      _showError('O nome não pode estar vazio.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true); // Começa a animação no botão

    try {
      // 1. A PARTE CHATA: TENTAR ATUALIZAR A PASSWORD
      // Só avançamos para aqui se o utilizador tiver escrito alguma coisa numa das 3 caixas de password
      if (oldPass.isNotEmpty || newPass.isNotEmpty || confirmPass.isNotEmpty) {
        
        // Mais proteções básicas...
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
        // O Firebase é muito picuinhas com a segurança. Para mudar a password, 
        // ele exige que o login tenha sido feito *recentemente*. Como não sabemos
        // quando foi, forçamos um "login invisível" aqui com a password antiga.
        try {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!, 
            password: oldPass
          );
          
          // Revalida a identidade do utilizador
          await user.reauthenticateWithCredential(credential);
          
          // Se passou o teste acima, podemos finalmente dar-lhe a nova password!
          await user.updatePassword(newPass);
          
        } on FirebaseAuthException catch (e) {
          // Se a password antiga que ele meteu estiver errada, apanhamos o erro aqui
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            _showError('A password atual está incorreta.');
          } else {
            _showError('Erro ao validar a password. Tenta novamente.');
          }
          setState(() => _isLoading = false);
          return; // Aborta! Não deixamos que o nome seja salvo se a password falhou.
        }
      }

      // 2. ATUALIZA O NOME 
      // Para poupar a internet e acessos ao Firebase, só atualizamos o nome se ele for realmente diferente do antigo.
      if (user.displayName != newName) {
        await user.updateDisplayName(newName);
        await user.reload(); // Força a Firebase a atualizar a "cache" local para o nome novo aparecer no resto da app
      }

      // SUCESSO TOTAL!
      if (mounted) { // Garante que o ecrã ainda está aberto antes de fazer pop
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: CERESColors.primaryDarkGreen),
        );
        context.pop(); // Volta para a página anterior
      }
      
    } catch (e) {
      if (mounted) _showError('Ocorreu um erro ao atualizar o perfil.');
    } finally {
      if (mounted) setState(() => _isLoading = false); // Para a rodinha quer corra bem, quer corra mal
    }
  }

  // --- WIDGET AJUDANTE (Para não repetir código) ---
  // Como as 3 caixas de password são 99% iguais, criei esta função para desenhar as caixas.
  // Recebe o texto (hint), o controlador, o estado do "olho" (obscure) e o que fazer ao clicar no olho (onToggle).
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
        // Bordas arredondadas e que ficam verdes quando clicamos
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Vemos se é o utilizador que "entrou sem conta" (anónimo)
    final isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
        title: const Text('Editar Perfil', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      // Se for convidado, esbarra aqui logo e vê uma mensagem. Senão, mostra o formulário.
      body: isGuest 
        ? const Center(child: Text('Contas de convidado não podem ser editadas.', style: TextStyle(color: CERESColors.textSecondary)))
        // O SingleChildScrollView é o melhor amigo dos formulários: impede que o teclado cubra os botões!
        : SingleChildScrollView( 
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- CAMPO DO NOME ---
                const Text('Nome de Apresentação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  maxLength: 20, // Ninguém precisa de um nome com mais de 20 letras aqui
                  decoration: InputDecoration(
                    counterText: "", // Esconde aquele contador manhoso "0/20" por baixo da caixa
                    hintText: 'O teu nome',
                    prefixIcon: const Icon(Icons.person_outline, color: CERESColors.textSecondary),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
                  ),
                ),
                
                // --- CAMPO DAS PASSWORDS ---
                // Esta parte toda só é desenhada no ecrã se o _isEmailAuth for verdade (O tal caso do Google Auth)
                if (_isEmailAuth) ...[
                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 24),
                  
                  const Text('Alterar Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 4),
                  const Text('Deixa em branco se não quiseres alterar.', style: TextStyle(fontSize: 13, color: CERESColors.textSecondary)),
                  const SizedBox(height: 16),
                  
                  // Chamamos o nosso widget ajudante para construir os 3 campos rapidamente!
                  _buildPasswordField('Password Atual', _oldPasswordController, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
                  const SizedBox(height: 12),
                  _buildPasswordField('Nova Password', _newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 12),
                  _buildPasswordField('Confirmar Nova Password', _confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                ],

                const SizedBox(height: 40),
                
                // --- BOTÃO DE GUARDAR ---
                SizedBox(
                  width: double.infinity, // Ocupa a largura toda do ecrã
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile, // Desativa os cliques se já estiver a guardar
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CERESColors.primaryDarkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0, // Sem sombra para um design mais plano e moderno
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar Alterações', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40), // Um respiro no fim da página para não colar o botão ao fundo do telemóvel
              ],
            ),
          ),
    );
  }
}