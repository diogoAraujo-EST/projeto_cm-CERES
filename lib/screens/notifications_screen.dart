import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';

// Este ecrã também é um StatelessWidget porque toda a reatividade (atualizar a lista)
// vem diretamente do StreamBuilder do Firebase, não precisamos de gerir variáveis de estado (State) à mão.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A ligação direta ao Firebase
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      
      // Cabeçalho super limpo com botão de voltar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CERESColors.textMain),
          onPressed: () => context.pop(), // GoRouter a mandar-nos para a página anterior
        ),
        title: const Text('Notificações', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      
      // --- O CORAÇÃO DO ECRÃ ---
      // Lemos as plantas todas do utilizador em tempo real. Se ele regar uma planta noutro ecrã, 
      // a notificação desaparece magicamente daqui!
      body: StreamBuilder<List<UserPlant>>(
        stream: firestoreService.getUserPlants(),
        builder: (context, snapshot) {
          
          // Tratamento para não piscar a rodinha verde se já tivermos dados em cache
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          final plants = snapshot.data ?? [];
          
          // O TRUQUE DE MESTRE DESTE ECRÃ: 
          // Não precisamos de uma base de dados de "notificações".
          // Apenas varremos as plantas e apanhamos as que têm a flag "isUrgent" (que passou da data de rega).
          final urgentPlants = plants.where((p) => p.isUrgent).toList();

          // Se a lista de urgentes estiver vazia...
          if (urgentPlants.isEmpty) {
            // Mostramos um estado de "Tudo Limpo" (Empty State) para recompensar o utilizador
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

          // Se houver plantas com sede, construímos a lista!
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

  // --- O COMPONENTE DA NOTIFICAÇÃO ---
  Widget _buildNotificationTile(BuildContext context, UserPlant plant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Um fundo laranja muuuito suave (5% de opacidade) para chamar à atenção sem gritar
        color: CERESColors.alertOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CERESColors.alertOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone da gota de água
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CERESColors.alertOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: CERESColors.alertOrange, size: 24),
          ),
          const SizedBox(width: 16),
          
          // Texto principal (Expanded para que não empurre a seta para fora do ecrã)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alerta de Rega', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                const SizedBox(height: 4),
                // Usamos o nome carinhoso que o utilizador deu à planta
                Text('A tua ${plant.nickname} precisa de água.', style: const TextStyle(color: CERESColors.textMain, height: 1.4)),
                const SizedBox(height: 8),
                // Uma ajuda rápida para o utilizador saber onde a encontrar pela casa
                Text('Local: ${plant.roomName}', style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
              ],
            ),
          ),
          
          // --- BOTÃO DE AÇÃO ---
          // A setinha à direita que convida ao clique
          IconButton(
            icon: const Icon(Icons.chevron_right, color: CERESColors.textSecondary),
            onPressed: () {
               // Envia o utilizador diretamente para a página dessa planta específica!
               // O "extra: plant" leva todos os dados da planta no "bolso" para a próxima página não ter de os descarregar de novo.
               context.push('/plant-details', extra: plant);
            },
          )
        ],
      ),
    );
  }
}