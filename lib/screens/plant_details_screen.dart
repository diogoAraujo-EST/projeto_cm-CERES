import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';
import '../models/room.dart';

class PlantDetailsScreen extends StatefulWidget {
  final UserPlant plant; // Recebe o objeto completo com os dados todos!

  const PlantDetailsScreen({
    super.key,
    required this.plant,
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
    _currentImageUrl = widget.plant.imageUrl;
  }

  // --- LÓGICA DE RECOMENDAÇÃO INTELIGENTE ---
   String _getDynamicRecommendation(Room room) {
    String rec = '';
    bool adjusted = false;

    // 1. Exterior vs Interior
    if (room.isExterior) {
      rec += '🌤️ O espaço (${room.name}) é exterior. O sol e o vento secam a terra mais depressa.\n\n';
      adjusted = true;
    } else {
      rec += '🏠 A planta está no interior (${room.name}), onde a evaporação é mais controlada.\n\n';
    }

    // 2. Luz da API vs Luz da Divisão
    String pLight = widget.plant.apiLight.toLowerCase();
    String rLight = room.lightLevel.toLowerCase();

    if (rLight == 'pouca luz' && (pLight.contains('muita') || pLight.contains('direta'))) {
      rec += '⚠️ Alerta de Luz: A planta prefere $pLight, mas a divisão tem $rLight. A fotossíntese será lenta, e a planta vai consumir água muito devagar. Para evitar apodrecer as raízes, o teu intervalo de rega foi aumentado.\n\n';
      adjusted = true;
    } else if (rLight == 'muita luz' && (pLight.contains('pouca') || pLight.contains('indireta'))) {
      rec += '⚠️ Alerta de Luz: A planta prefere $pLight, mas a divisão tem $rLight. O excesso de sol vai secar a terra rapidamente. Para evitar que a planta seque, o teu intervalo de rega foi reduzido.\n\n';
      adjusted = true;
    } else {
      rec += '✅ Excelente! O nível de luz da divisão ($rLight) é perfeitamente adequado para as necessidades desta planta.\n\n';
    }

    // 3. Conclusão Final
    if (adjusted) {
      rec += '💡 O algoritmo CERES ajustou automaticamente a rega para cada ${widget.plant.wateringInterval} dias em vez do padrão da espécie!';
    } else {
      rec += '💡 A rega foi mantida no padrão ideal de ${widget.plant.wateringInterval} dias.';
    }

    return rec;
  }

  // Lógica de Foto (mantém-se)
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
      if (pickedFile != null) {
        setState(() => _isUploadingImage = true);
        final newUrl = await _firestoreService.updatePlantImage(widget.plant.id, File(pickedFile.path));
        setState(() { _currentImageUrl = newUrl; _isUploadingImage = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto atualizada!'), backgroundColor: CERESColors.primaryDarkGreen));
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
            const Padding(padding: EdgeInsets.all(16.0), child: Text('Alterar foto da Planta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain))),
            ListTile(leading: const Icon(Icons.camera_alt, color: CERESColors.primaryDarkGreen), title: const Text('Tirar foto com a Câmara'), onTap: () => _pickImage(ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library, color: CERESColors.primaryDarkGreen), title: const Text('Escolher da Galeria'), onTap: () => _pickImage(ImageSource.gallery)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _waterPlant() async {
    setState(() => _isWatering = true);
    try {
      await _firestoreService.waterPlant(widget.plant.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('💧 Regaste a ${widget.plant.nickname}!'), backgroundColor: CERESColors.primaryDarkGreen, behavior: SnackBarBehavior.floating));
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
      await _firestoreService.deletePlant(widget.plant.id);
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
                GestureDetector(
                  onLongPress: _showImageSourceDialog,
                  child: Stack(
                    children: [
                      Container(
                        height: 350, width: double.infinity,
                        decoration: BoxDecoration(color: CERESColors.primaryDarkGreen.withValues(alpha: 0.08), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                          child: Image.network(_currentImageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.park, size: 150, color: CERESColors.primaryDarkGreen))),
                        ),
                      ),
                      if (_isUploadingImage)
                        Container(height: 350, width: double.infinity, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
                      if (!_isUploadingImage)
                        Positioned(bottom: 20, right: 20, child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)]), child: IconButton(icon: const Icon(Icons.add_a_photo, color: CERESColors.primaryDarkGreen, size: 22), onPressed: _showImageSourceDialog)))
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]), child: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop())),
                        const SizedBox(width: 12),
                        Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]), child: IconButton(icon: _isWatering ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.water_drop, color: Colors.blueAccent), onPressed: _isWatering ? null : _waterPlant)),
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
                      Expanded(child: Text(widget.plant.nickname, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CERESColors.textMain))),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: CERESColors.textSecondary),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) { if (value == 'Eliminar') _deletePlant(); },
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
                    decoration: BoxDecoration(color: widget.plant.isUrgent ? const Color(0xFFD9774B).withValues(alpha: 0.1) : CERESColors.primaryDarkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop, color: widget.plant.isUrgent ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.plant.statusText, style: TextStyle(fontWeight: FontWeight.bold, color: widget.plant.isUrgent ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen)),
                            Text(widget.plant.lastWateredText, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Sobre a planta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 16),
                  
                  // Agora usamos os dados REAIS da API!
                  _buildDetailRow('Espécie', widget.plant.speciesName),
                  const Divider(color: Color(0xFFEEEEEE), height: 24),
                  _buildDetailRow('Luz Ideal', widget.plant.apiLight),
                  const Divider(color: Color(0xFFEEEEEE), height: 24),
                  _buildDetailRow('Descrição', widget.plant.apiDescription),
                  const Divider(color: Color(0xFFEEEEEE), height: 24),
                  _buildDetailRow('Dica', widget.plant.apiCare),
                  
                  const SizedBox(height: 32),
                  const Text('Recomendação de Rega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 8),
                  
                  // MOTOR DE INTELIGÊNCIA: Combina a Divisão com as regras da Planta!
                  StreamBuilder<List<Room>>(
                    stream: _firestoreService.getUserRooms(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text('A analisar as condições...', style: TextStyle(color: Colors.grey));
                      
                      // Encontra a divisão da planta
                      final room = snapshot.data!.firstWhere(
                        (r) => r.name == widget.plant.roomName, 
                        orElse: () => Room(name: 'Desconhecido', lightLevel: 'Luz Média', isExterior: false)
                      );

                      String customRec = _getDynamicRecommendation(room);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Text(customRec, style: const TextStyle(fontSize: 13, color: CERESColors.textSecondary, height: 1.5)),
                      );
                    }
                  ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(title, style: const TextStyle(color: CERESColors.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.w500, height: 1.4))),
      ],
    );
  }
}