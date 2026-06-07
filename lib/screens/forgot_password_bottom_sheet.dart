import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

// Repara que isto não é um "Screen" (ecrã inteiro), é um BottomSheet.
// Vai ser desenhado por cima da página de Login.
class ForgotPasswordBottomSheet extends StatefulWidget {
  // Recebemos esta função do pai (a página de Login) para sabermos o que fazer 
  // quando o utilizador clica em "Voltar para o Login".
  final VoidCallback onBackToLogin;

  const ForgotPasswordBottomSheet({super.key, required this.onBackToLogin});

  @override
  State<ForgotPasswordBottomSheet> createState() => _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends State<ForgotPasswordBottomSheet> {
  // Para ler o email que o utilizador escreve
  final _emailController = TextEditingController();
  
  // O nosso serviço que fala com o Firebase
  final _authService = AuthService();
  
  // Controlo da interface
  bool _isLoading = false;
  
  // Em vez de mostrar avisos (SnackBars) para os erros de email, vamos guardar 
  // o erro aqui para mostrar diretamente debaixo da caixa de texto (fica com melhor aspeto)
  String? _emailError;

  @override
  void dispose() {
    // Como sempre, limpar a memória quando o menu fecha
    _emailController.dispose();
    super.dispose();
  }

  // --- A LÓGICA DE RECUPERAÇÃO ---
  Future<void> _recoverPassword() async {
    // 1. Limpa qualquer erro antigo antes de tentar outra vez
    setState(() => _emailError = null);
    
    // 2. Apanha o email e corta espaços vazios que o utilizador possa ter deixado no fim sem querer
    final email = _emailController.text.trim();

    // Proteção básica: não enviar emails em branco para o Firebase
    if (email.isEmpty) {
      setState(() => _emailError = 'Por favor, introduza o seu email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Manda o Firebase fazer o seu trabalho e enviar o email de recuperação
      await _authService.sendPasswordReset(email);
      
      if (mounted) {
        Navigator.pop(context); // Fecha logo este menu que deslizou de baixo
        
        // Avisa que correu tudo bem
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de recuperação enviado! Verifique a sua caixa de entrada. 📩'),
            backgroundColor: CERESColors.primaryDarkGreen,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Tratamento de erros específicos do Firebase
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          // Traduzimos os códigos de erro feios do Firebase para português simpático
          _emailError = 'Este email não é válido ou não está registado';
        } else {
          _emailError = 'Erro ao enviar o pedido. Tente novamente.';
        }
      });
    } catch (e) {
      // Se a internet falhar ou algo estranho acontecer
      setState(() => _emailError = 'Ocorreu um erro inesperado.');
    } finally {
      // Desliga a rodinha quer corra bem, quer dê erro
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // O TRUQUE MÁGICO PARA O TECLADO!
    // Isto calcula a altura do teclado do telemóvel quando ele aparece.
    // Vamos somar isto ao "bottom padding" lá em baixo para garantir que 
    // este menu sobe e não fica escondido atrás do teclado.
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        // Arredonda apenas os cantos de cima para dar o efeito de gaveta
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      // Aqui aplicamos a tal margem do teclado (24 de base + a altura do teclado)
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24 + keyboardPadding),
      child: SingleChildScrollView(
        // MainAxisSize.min faz com que o menu ocupe apenas o espaço estritamente necessário 
        // e não o ecrã inteiro de alto a baixo
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Aquele tracinho cinzento no topo que indica "podes puxar-me para baixo para fechar"
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Recuperar Password 🔑',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CERESColors.textMain),
            ),
            const SizedBox(height: 8),
            
            const Text(
              'Introduza o email associado à sua conta. Enviaremos um link para redefinir a sua palavra-passe.',
              style: TextStyle(fontSize: 14, color: CERESColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),

            // --- CAIXA DE EMAIL ---
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress, // Mostra o teclado já com o "@" à mão
              
              // Truque de UX: Assim que a pessoa começa a corrigir o email apagando uma letra, 
              // limpamos o texto de erro vermelho para não a deixar ansiosa.
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              
              decoration: InputDecoration(
                hintText: 'Email de registo',
                errorText: _emailError, // Se houver erro, o próprio TextField trata de o pintar de vermelho!
                prefixIcon: const Icon(Icons.email_outlined, color: CERESColors.textSecondary),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // --- BOTÃO DE ENVIAR ---
            ElevatedButton(
              onPressed: _isLoading ? null : _recoverPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: CERESColors.primaryDarkGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enviar Link', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),

            // --- BOTÃO VOLTAR ---
            TextButton(
              // Chama a função que veio empacotada do ecrã anterior (LoginScreen)
              onPressed: widget.onBackToLogin,
              child: const Text('Voltar para o Login', style: TextStyle(color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}