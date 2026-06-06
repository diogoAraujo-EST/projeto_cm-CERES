import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CERESColors.textMain),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notificações', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<UserPlant>>(
        stream: firestoreService.getUserPlants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          final plants = snapshot.data ?? [];
          // Filtramos apenas as que precisam de rega!
          final urgentPlants = plants.where((p) => p.isUrgent).toList();

          if (urgentPlants.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tudo em dia!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  SizedBox(height: 8),
                  Text('Não tens novos alertas de rega.', style: TextStyle(color: CERESColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: urgentPlants.length,
            itemBuilder: (context, index) {
              final plant = urgentPlants[index];
              return _buildNotificationTile(context, plant);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, UserPlant plant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CERESColors.alertOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CERESColors.alertOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CERESColors.alertOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: CERESColors.alertOrange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alerta de Rega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                const SizedBox(height: 4),
                Text('A tua ${plant.nickname} precisa de água.', style: const TextStyle(color: CERESColors.textMain, height: 1.4)),
                const SizedBox(height: 8),
                Text('Local: ${plant.roomName}', style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
              ],
            ),
          ),
          // Botão rápido para ir regar
          IconButton(
            icon: const Icon(Icons.chevron_right, color: CERESColors.textSecondary),
            onPressed: () {
               context.push('/plant-details', extra: plant);
            },
          )
        ],
      ),
    );
  }
}