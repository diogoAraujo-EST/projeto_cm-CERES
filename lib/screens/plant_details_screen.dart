import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';

class PlantDetailsScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final String plantStatus;
  final String lastWatered;
  final bool isUrgent;
  final String imageUrl;

  const PlantDetailsScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    required this.plantStatus,
    required this.lastWatered,
    required this.isUrgent,
    required this.imageUrl,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  bool _isWatering = false;
  bool _isUploadingImage = false;
  late String _currentImageUrl;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Guardamos a imagem num estado local para a UI atualizar quando enviarmos uma nova
    _currentImageUrl = widget.imageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Fecha o modal
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
      
      if (pickedFile != null) {
        setState(() => _isUploadingImage = true);
        
        // Faz o upload e recebe o novo URL
        final newUrl = await _firestoreService.updatePlantImage(widget.plantId, File(pickedFile.path));
        
        setState(() {
          _currentImageUrl = newUrl;
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto atualizada!'), backgroundColor: CERESColors.primaryDarkGreen));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao atualizar foto.'), backgroundColor: Colors.red));
      }
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
              child: Text('Alterar foto da Planta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
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

  Future<void> _waterPlant() async {
    setState(() => _isWatering = true);
    try {
      await _firestoreService.waterPlant(widget.plantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('💧 Regaste a ${widget.plantName}!'), backgroundColor: CERESColors.primaryDarkGreen, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao regar planta.'), backgroundColor: Colors.red));
        setState(() => _isWatering = false);
      }
    }
  }

  Future<void> _deletePlant() async {
    try {
      await _firestoreService.deletePlant(widget.plantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Planta eliminada.'), backgroundColor: Colors.red));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao eliminar planta.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // CLIQUE LONGO PARA TROCAR A FOTO
                GestureDetector(
                  onLongPress: _showImageSourceDialog,
                  child: Stack(
                    children: [
                      Container(
                        height: 350,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: CERESColors.primaryDarkGreen.withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                          child: Image.network(
                            _currentImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.park, size: 150, color: CERESColors.primaryDarkGreen)),
                          ),
                        ),
                      ),
                      
                      // Indicador de Loading por cima da imagem durante o Upload
                      if (_isUploadingImage)
                        Container(
                          height: 350,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                          ),
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),

                      // Botão visível para os utilizadores perceberem que podem trocar
                      if (!_isUploadingImage)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)]),
                            child: IconButton(
                              icon: const Icon(Icons.add_a_photo, color: CERESColors.primaryDarkGreen, size: 22),
                              onPressed: _showImageSourceDialog,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
                          child: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
                          child: IconButton(
                            icon: _isWatering 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.water_drop, color: Colors.blueAccent),
                            onPressed: _isWatering ? null : _waterPlant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.plantName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CERESColors.textMain))),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: CERESColors.textSecondary),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          if (value == 'Eliminar') _deletePlant();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Editar', child: Text('Editar Planta')),
                          const PopupMenuItem(value: 'Pausar', child: Text('Pausar Regas')),
                          const PopupMenuDivider(),
                          const PopupMenuItem(value: 'Eliminar', child: Text('Eliminar Planta', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.isUrgent ? const Color(0xFFD9774B).withValues(alpha: 0.1) : CERESColors.primaryDarkGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop, color: widget.isUrgent ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.plantStatus, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isUrgent ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen)),
                            if (widget.lastWatered.isNotEmpty)
                              Text(widget.lastWatered, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Sobre a planta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Tipo', 'Informação na API'),
                  const Divider(color: Color(0xFFEEEEEE), height: 30),
                  _buildDetailRow('Luz', 'Informação na API'),
                  const Divider(color: Color(0xFFEEEEEE), height: 30),
                  _buildDetailRow('Temperatura ideal', '18–27 °C'),
                  const Divider(color: Color(0xFFEEEEEE), height: 30),
                  _buildDetailRow('Humidade ideal', '50–70%'),
                  const SizedBox(height: 32),
                  const Text('Frequência de rega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 8),
                  const Text('Configuração guardada', style: TextStyle(fontSize: 14, color: CERESColors.textMain, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Ajustamos esta recomendação com base nas condições do teu espaço.', style: TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(title, style: const TextStyle(color: CERESColors.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.w500))),
      ],
    );
  }
}