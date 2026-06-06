import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../models/user_plant.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();
    
    String displayName = 'Utilizador';
    if (user != null) {
      if (user.isAnonymous) {
        displayName = 'Convidado';
      } else if (user.displayName != null && user.displayName!.isNotEmpty) {
        displayName = user.displayName!.length > 20 
            ? user.displayName!.substring(0, 20) 
            : user.displayName!;
      }
    }

    return SafeArea(
      child: Column(
        children: [
          // CABEÇALHO (Estático, fica fora do Stream para não piscar ao carregar)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Olá, $displayName!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                        const SizedBox(width: 4),
                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: Image.asset('assets/images/ceres_logo_only_2.png', height: 30),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Aqui está o resumo das tuas plantas.', style: TextStyle(fontSize: 14, color: CERESColors.textSecondary)),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                  child: IconButton(icon: const Icon(Icons.notifications_none, color: CERESColors.textMain), onPressed: () {}),
                )
              ],
            ),
          ),

          // CORPO (Lê as plantas do Firebase em tempo real)
          Expanded(
            child: StreamBuilder<List<UserPlant>>(
              stream: firestoreService.getUserPlants(),
              builder: (context, snapshot) {
                // Estado de Carregamento
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
                }

                // Estado de Erro
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar as plantas.', style: TextStyle(color: Colors.red)));
                }

                final plants = snapshot.data ?? [];
                
                // Se não tiver plantas, mostra um aviso para adicionar
                if (plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.park_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Ainda não tens plantas.', style: TextStyle(fontSize: 18, color: CERESColors.textSecondary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/add-plant'),
                          child: const Text('Adicionar a minha primeira planta', style: TextStyle(color: CERESColors.primaryDarkGreen, fontSize: 16)),
                        )
                      ],
                    ),
                  );
                }

                // Filtrar as plantas pela urgência usando os getters do nosso Model
                final urgentPlants = plants.where((p) => p.isUrgent).toList();
                final upcomingPlants = plants.where((p) => !p.isUrgent).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  children: [
                    // ALERTA AZUL (Número dinâmico)
                    const SizedBox(height: 24),

                    // LISTA DE HOJE
                    const Text('Hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                    const SizedBox(height: 16),                    
                    Container(

                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.lightBlue, size: 28),
                          const SizedBox(width: 16),
                          Text('${urgentPlants.length} plantas precisam de rega', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: CERESColors.textMain)),
                        ],
                      ),
                    ),

                    
                    if (urgentPlants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Text('Tudo regado para hoje!', style: TextStyle(color: CERESColors.textSecondary)),
                      ),

                    ...urgentPlants.map((plant) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildPlantCard(context, plant),
                    )),
                    
                    const SizedBox(height: 32),
                    
                    // LISTA PRÓXIMAS REGAS
                    const Text('Próximas regas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                    const SizedBox(height: 16),

                    if (upcomingPlants.isEmpty)
                      const Text('Não tens regas agendadas.', style: TextStyle(color: CERESColors.textSecondary)),

                    ...upcomingPlants.map((plant) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildPlantCard(context, plant),
                    )),
                    
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // O cartão agora recebe o objeto UserPlant inteiro
  Widget _buildPlantCard(BuildContext context, UserPlant plant) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Envia o ID da planta e os dados essenciais para o ecrã de detalhes
        context.push(
          '/plant-details', 
          extra: {
            'id': plant.id, // Fundamental para depois podermos regar na BD
            'name': plant.nickname,
            'status': plant.statusText,
            'lastWatered': plant.lastWateredText,
            'isUrgent': plant.isUrgent,
            'imageUrl': plant.imageUrl, // Passamos a imagem real também
          }
        );
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
            // Imagem real vinda da API
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  plant.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.park, color: Colors.grey),
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
                  Text(
                    plant.statusText, 
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 14, 
                      color: plant.isUrgent ? const Color(0xFFD9774B) : CERESColors.textMain, 
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(plant.lastWateredText, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}