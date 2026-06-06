import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // Importante!
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUploadingImage = false;

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Fecha o BottomSheet de escolha

    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Reduz tamanho para poupar espaço no Storage
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() => _isUploadingImage = true);
        
        File imageFile = File(pickedFile.path);
        await _firestoreService.uploadProfilePicture(imageFile);
        
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
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

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
      child: StreamBuilder<DocumentSnapshot>(
        // Ouve as alterações no documento do utilizador no Firestore
        stream: _firestoreService.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          String displayName = 'Utilizador';
          String displayEmail = 'Sem e-mail registado';
          String avatarLetter = 'U';
          String? photoUrl;
          bool isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['name'] ?? 'Utilizador';
            displayEmail = data['email'] ?? '';
            photoUrl = data['photoUrl'];
            
            if (photoUrl != null && photoUrl.isEmpty) photoUrl = null;
            if (displayName.isNotEmpty) avatarLetter = displayName[0].toUpperCase();
            if (isGuest) avatarLetter = 'C';
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              const Text('Perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
              const SizedBox(height: 32),
              
              // Avatar Clicável
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: isGuest ? null : _showImageSourceDialog,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: CERESColors.primaryDarkGreen,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: _isUploadingImage
                                ? const CircularProgressIndicator(color: Colors.white)
                                : (photoUrl == null
                                    ? (isGuest 
                                        ? const Icon(Icons.person_outline, size: 48, color: Colors.white)
                                        : Text(avatarLetter, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)))
                                    : null),
                          ),
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
                    Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                    const SizedBox(height: 4),
                    Text(isGuest ? 'Acesso temporário' : displayEmail, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Menu de Opções
              _buildMenuTile(Icons.eco, 'As minhas plantas', () => context.go('/plants')),
              _buildMenuTile(Icons.settings, 'Configurações', () => context.push('/settings')),
              _buildMenuTile(Icons.help_outline, 'Ajuda e Suporte', () => context.push('/help')),
              
              const Divider(height: 40),
              
              _buildMenuTile(Icons.logout, 'Sair da Conta', () async {
                await _authService.signOut();
                if (context.mounted) context.go('/');
              }, isDestructive: true),
            ],
          );
        }
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withValues(alpha: 0.1) : CERESColors.primaryDarkGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDestructive ? Colors.red : CERESColors.primaryDarkGreen),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : CERESColors.textMain)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}