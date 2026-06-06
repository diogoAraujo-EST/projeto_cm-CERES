import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../models/plant_species.dart';
import '../models/room.dart';
import '../models/user_plant.dart';
import '../services/plant_api_service.dart';
import '../services/firestore_service.dart';
import 'dart:async';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nicknameController = TextEditingController();
  final _searchController = TextEditingController();
  
  final _apiService = PlantApiService();
  final _firestoreService = FirestoreService();
  
  Timer? _debounce;

  List<PlantSpecies> _speciesList = [];
  bool _isLoadingSpecies = true;
  bool _isSaving = false;
  
  PlantSpecies? _selectedSpecies;
  Room? _selectedRoom;
  File? _selectedImage; // A foto tirada pelo utilizador

  @override
  void initState() {
    super.initState();
    _loadSpecies(''); 
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Fecha o modal
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
    
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
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
              child: Text('Adicionar foto da Planta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: CERESColors.primaryDarkGreen),
              title: const Text('Tirar foto'),
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

  Future<void> _loadSpecies(String query) async {
    setState(() => _isLoadingSpecies = true);
    try {
      final results = await _apiService.fetchSpecies(query: query);
      setState(() {
        _speciesList = results;
        _isLoadingSpecies = false;
      });
    } catch (e) {
      setState(() {
        _speciesList = [];
        _isLoadingSpecies = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadSpecies(query.trim());
    });
  }

  void _showCreateRoomSheet() {
    // ... Código inalterado ...
    final nameController = TextEditingController();
    String selectedLight = 'Luz Média';
    bool isExterior = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24 + keyboardPadding),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    const Text('Criar Nova Divisão 🏠', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Escritório, Varanda...',
                        filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Nível de Iluminação', style: TextStyle(fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedLight,
                      items: ['Muita Luz', 'Luz Média', 'Pouca Luz'].map((String val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedLight = val);
                      },
                      decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('É um espaço exterior?', style: TextStyle(fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                      activeColor: CERESColors.primaryDarkGreen,
                      value: isExterior,
                      onChanged: (val) => setModalState(() => isExterior = val),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          await _firestoreService.addRoom(name, selectedLight, isExterior);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CERESColors.primaryDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Guardar Divisão', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePlant() async {
    if (_selectedSpecies == null) {
      _showSnackBar('Por favor, selecione uma espécie de planta.', Colors.red);
      return;
    }
    if (_selectedRoom == null) {
      _showSnackBar('Por favor, selecione ou crie uma divisão para a planta.', Colors.red);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Erro de autenticação. Inicie sessão novamente.', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    final String finalNickname = _nicknameController.text.trim().isNotEmpty 
        ? _nicknameController.text.trim() 
        : _selectedSpecies!.name;

    final newPlant = UserPlant(
      id: '', 
      userId: user.uid,
      nickname: finalNickname,
      speciesName: _selectedSpecies!.name,
      imageUrl: _selectedSpecies!.imageUrl,
      wateringInterval: _selectedSpecies!.defaultWateringInterval,
      lastWatered: DateTime.now(),
      roomName: _selectedRoom!.name,
      wateringHistory: [DateTime.now()],
    );

    try {
      // Passamos também o ficheiro da imagem opcional
      await _firestoreService.addPlant(newPlant, imageFile: _selectedImage);
      if (mounted) {
        _showSnackBar('🌿 $finalNickname adicionada com sucesso!', CERESColors.primaryDarkGreen);
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Erro ao guardar a planta na nuvem.', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Adicionar Planta', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AVATAR FOTO DA PLANTA
            Center(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: CERESColors.primaryDarkGreen.withValues(alpha: 0.1),
                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                  child: _selectedImage == null
                      ? const Icon(Icons.add_a_photo, size: 40, color: CERESColors.primaryDarkGreen)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('Foto (Opcional)', style: TextStyle(color: CERESColors.textSecondary))),
            const SizedBox(height: 24),

            const Text('Nome da Planta (Opcional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                hintText: 'Ex: A minha Monstera, Fred...',
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Pesquisar Espécie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Escreva o nome da planta...', prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 140,
              child: _isLoadingSpecies
                  ? const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen))
                  : _speciesList.isEmpty
                      ? const Center(child: Text('Nenhuma espécie encontrada.', textAlign: TextAlign.center))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _speciesList.length,
                          itemBuilder: (context, index) {
                            final species = _speciesList[index];
                            final isSelected = _selectedSpecies?.id == species.id;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedSpecies = species),
                              child: Container(
                                width: 110, margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? CERESColors.primaryDarkGreen.withValues(alpha: 0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isSelected ? CERESColors.primaryDarkGreen : Colors.grey.shade200, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                                        child: Image.network(species.imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.park, color: Colors.grey))),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                      child: Text(species.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: CERESColors.textMain)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            if (_selectedSpecies != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco_rounded, color: CERESColors.primaryDarkGreen, size: 20),
                        const SizedBox(width: 8),
                        Text('Sobre a ${_selectedSpecies!.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: CERESColors.primaryDarkGreen, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_selectedSpecies!.description, style: const TextStyle(fontSize: 13, color: CERESColors.textSecondary, height: 1.4)),
                    const SizedBox(height: 12),
                    Row(children: [const Icon(Icons.water_drop_outlined, color: Colors.blue, size: 18), const SizedBox(width: 8), Text('Rega: A cada ${_selectedSpecies!.defaultWateringInterval} dias', style: const TextStyle(fontSize: 13, color: CERESColors.textMain, fontWeight: FontWeight.w600))]),
                    const SizedBox(height: 8),
                    Row(children: [const Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 18), const SizedBox(width: 8), Text('Luz: ${_selectedSpecies!.lightLevel}', style: const TextStyle(fontSize: 13, color: CERESColors.textMain, fontWeight: FontWeight.w600))]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: CERESColors.primaryDarkGreen.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.tips_and_updates_outlined, color: CERESColors.primaryDarkGreen, size: 18), const SizedBox(width: 8), Expanded(child: Text('Dica: ${_selectedSpecies!.careInstructions}', style: const TextStyle(fontSize: 13, color: CERESColors.primaryDarkGreen, fontStyle: FontStyle.italic)))]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Divisão da Casa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                TextButton.icon(
                  onPressed: _showCreateRoomSheet,
                  icon: const Icon(Icons.add, size: 16, color: CERESColors.primaryDarkGreen),
                  label: const Text('Criar Divisão', style: TextStyle(color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<Room>>(
              stream: _firestoreService.getUserRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
                final rooms = snapshot.data ?? [];
                if (rooms.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(border: Border.all(color: Colors.amber.shade200), color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [Icon(Icons.home_work_outlined, color: Colors.amber.shade800), const SizedBox(width: 12), const Expanded(child: Text('Ainda não tens nenhuma divisão criada. Cria a tua primeira divisão acima!', style: TextStyle(color: CERESColors.textMain, fontSize: 13, fontWeight: FontWeight.w500)))]),
                  );
                }
                return Wrap(
                  spacing: 8.0, runSpacing: 4.0,
                  children: rooms.map((room) {
                    final isSelected = _selectedRoom?.name == room.name;
                    return ChoiceChip(
                      label: Text(room.name), selected: isSelected, selectedColor: CERESColors.primaryDarkGreen, backgroundColor: Colors.grey.shade50,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : CERESColors.textMain, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      onSelected: (selected) => setState(() => _selectedRoom = selected ? room : null),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isSaving ? null : _savePlant,
              style: ElevatedButton.styleFrom(
                backgroundColor: CERESColors.primaryDarkGreen, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Guardar Planta', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}