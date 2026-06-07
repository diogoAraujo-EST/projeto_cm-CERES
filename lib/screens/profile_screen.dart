import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Importante!
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// O ecrã de perfil é um StatefulWidget porque tem de lidar com interações locais, 
// nomeadamente o "loading" em cima da foto enquanto a imagem nova é enviada para a cloud.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Chamamos os nossos "trabalhadores" de serviço
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  // Flag que vai pintar o avatar de escuro e rodar um loading se estivermos a subir uma foto
  bool _isUploadingImage = false;

  // --- LÓGICA DE UPLOAD DA FOTO DO UTILIZADOR ---
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Fecha o BottomSheet de escolha de câmara/galeria logo à partida

    final picker = ImagePicker();
    try {
      // Abre a interface do telemóvel para escolher a foto.
      // O truque da imageQuality e do maxWidth salva montes de largura de banda e espaço no Firebase Storage!
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, 
        maxWidth: 800,
      );

      // Se a pessoa escolheu de facto uma foto (e não clicou em "cancelar")...
      if (pickedFile != null) {
        setState(() => _isUploadingImage = true); // Liga o loading no ecrã
        
        File imageFile = File(pickedFile.path);
        
        // Pede ao nosso serviço para guardar a foto no Firebase
        await _firestoreService.uploadProfilePicture(imageFile);
        
        // Se a página ainda estiver aberta depois do upload terminar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil atualizada com sucesso!'), backgroundColor: CERESColors.primaryDarkGreen),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar foto.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Quer falhe ou corra bem, desliga o loading.
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // O menuzinho clássico que surge de baixo para perguntar: "Selfie agora ou foto antiga?"
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Alterar foto de perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: CERESColors.primaryDarkGreen),
              title: const Text('Tirar foto com a Câmara'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: CERESColors.primaryDarkGreen),
              title: const Text('Escolher da Galeria'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // --- MAGIA DO STREAMBUILDER ---
      // Em vez de lermos a Firebase uma vez e os dados ficarem "presos", 
      // abrimos uma escuta ativa (stream) para o documento do utilizador.
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserProfile(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          // Variáveis de proteção caso o utilizador não tenha preenchido os dados todos
          String displayName = 'Utilizador';
          String displayEmail = 'Sem e-mail registado';
          String avatarLetter = 'U'; // Letra para meter no balão se não houver foto
          String? photoUrl;
          
          // Confirma rapidamente se é o convidado (anonymous)
          bool isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

          // Se há dados frescos do Firebase, extraímos para as nossas variáveis seguras
          if (snapshot.hasData && snapshot.data!.exists) {
            // Transformamos a mistela do Firebase num "Map" em Dart
            final data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['name'] ?? 'Utilizador';
            displayEmail = data['email'] ?? '';
            photoUrl = data['photoUrl'];
            
            // Segurança extra: um link vazio '' é diferente de um link nulo null, 
            // e o widget de imagem não gosta de links vazios.
            if (photoUrl != null && photoUrl.isEmpty) photoUrl = null;
            
            // Pega na primeira letra do nome ("João" -> "J") para o avatar
            if (displayName.isNotEmpty) avatarLetter = displayName[0].toUpperCase();
            
            // Se for convidado forçamos a letra a "C" para não chocar
            if (isGuest) avatarLetter = 'C';
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Cabeçalho estático
              const Text('Perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
              const SizedBox(height: 32),
              
              // --- ÁREA DO AVATAR E DO NOME ---
              Center(
                child: Column(
                  children: [
                    // O GestureDetector permite que a foto inteira seja "clicável"
                    GestureDetector(
                      // Mas... se for convidado, ele não pode mudar de foto! O onTap fica null.
                      onTap: isGuest ? null : _showImageSourceDialog,
                      child: Stack(
                        children: [
                          // O círculo principal
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: CERESColors.primaryDarkGreen,
                            // Se tiver link mostra a foto da net, se não tiver mete fundo nulo para mostrar a letra
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            
                            // A lógica do que vai "dentro" do círculo é bué porreira:
                            child: _isUploadingImage
                                ? const CircularProgressIndicator(color: Colors.white) // 1. Se tá a carregar, rodinha
                                : (photoUrl == null // 2. Se NÃO tem foto...
                                    ? (isGuest 
                                        ? const Icon(Icons.person_outline, size: 48, color: Colors.white) // ... e é convidado, mete um ícone boneco
                                        : Text(avatarLetter, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold))) // ... e é normal, mete a letra!
                                    : null), // 3. Se TEM foto, a backgroundImage trata do assunto sozinha.
                          ),
                          
                          // O pequeno botãozinho extra de câmara no canto (badge) para as pessoas perceberem
                          // visualmente que a zona é clicável (mas não mostramos ao convidado!)
                          if (!isGuest && !_isUploadingImage)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                                child: const Icon(Icons.camera_alt, size: 20, color: CERESColors.primaryDarkGreen),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- OS TEXTOS ---
                    Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                    const SizedBox(height: 4),
                    Text(isGuest ? 'Acesso temporário' : displayEmail, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- LISTA DE OPÇÕES ---
              // Fomos buscar a função ajudante cá a baixo para o código não ficar uma trip de repetitivo
              _buildMenuTile(Icons.eco, 'As minhas plantas', () => context.go('/plants')),
              _buildMenuTile(Icons.settings, 'Configurações', () => context.push('/settings')),
              _buildMenuTile(Icons.help_outline, 'Ajuda e Suporte', () => context.push('/help')),
              
              const Divider(height: 40),
              
              // O botão de Log Out é vermelho e feio de propósito para o utilizador pensar duas vezes!
              _buildMenuTile(Icons.logout, 'Sair da Conta', () async {
                await _authService.signOut(); // Limpa as credenciais locais
                if (context.mounted) context.go('/'); // Manda-o de volta para a rua (WelcomeScreen)
              }, isDestructive: true),
            ],
          );
        }
      ),
    );
  }

  // --- WIDGET AJUDANTE (Menu Tile) ---
  // Uma função que cospe "ListTiles" com um design consistente para não termos de escrever 20 linhas por cada botão do menu.
  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        // Se for "isDestructive" (tipo apagar ou sair), pinta de vermelho. Se for normal, pinta de verde CERES.
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withValues(alpha: 0.1) : CERESColors.primaryDarkGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : CERESColors.primaryDarkGreen),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : CERESColors.textMain)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey), // A setinha para a frente
      onTap: onTap, // O que fazer quando clica!
    );
  }
}