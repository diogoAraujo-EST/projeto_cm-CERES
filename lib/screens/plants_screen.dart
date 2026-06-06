import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('As Minhas Plantas', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: CERESColors.textMain),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barra de pesquisa a ser implementada...')));
            },
          ),
        ],
      ),
      // Substituímos a lista fixa pelo StreamBuilder da Firebase
      body: StreamBuilder<List<UserPlant>>(
        stream: firestoreService.getUserPlants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar as plantas.', style: TextStyle(color: Colors.red)));
          }

          final plants = snapshot.data ?? [];

          if (plants.isEmpty) {
            return const Center(
              child: Text('Ainda não tens plantas guardadas.', style: TextStyle(color: CERESColors.textSecondary, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildPlantItem(context, plant),
              );
            },
          );
        },
      ),
    );
  }

  // O cartão atualizado para receber e passar dados reais do Firebase
  Widget _buildPlantItem(BuildContext context, UserPlant plant) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.push('/plant-details', extra: plant);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  plant.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.park, color: CERESColors.primaryDarkGreen),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                  const SizedBox(height: 4),
                  // Mostra a divisão da casa como detalhe
                  Text('${plant.roomName} • ${plant.speciesName}', style: const TextStyle(fontSize: 13, color: CERESColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}