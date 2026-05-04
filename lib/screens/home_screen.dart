import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'plant_details_screen.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Olá, Mariana!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                      const SizedBox( width: 4,),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Image.asset(
                        'assets/images/ceres_logo_only_2.png',
                        height: 30,
                        ),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  Text('Aqui está o resumo das tuas plantas.', style: TextStyle(fontSize: 14, color: CERESColors.textSecondary)),
                
                
                
                ],
                
              ),
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                child: IconButton(icon: const Icon(Icons.notifications_none, color: CERESColors.textMain), onPressed: () {}),
              )
            ],
          ),
          const SizedBox(height: 32),

          const Text('Hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Row(
              children: [
                Icon(Icons.water_drop, color: Colors.lightBlue, size: 28),
                SizedBox(width: 16),
                Text('2 plantas precisam de rega', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: CERESColors.textMain)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildPlantCard(context, 'Monstera', 'Precisa de rega', 'Última rega: há 2 dias', true),
          const SizedBox(height: 12),
          _buildPlantCard(context, 'Ficus Lyrata', 'Precisa de rega', 'Última rega: há 1 dia', true),
          
          const SizedBox(height: 32),
          const Text('Próximas regas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          const SizedBox(height: 16),
          
          _buildPlantCard(context, 'Samambaia', 'Amanhã', '', false),
          const SizedBox(height: 12),
          _buildPlantCard(context, 'Suculenta', 'Em 2 dias', '', false),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPlantCard(BuildContext context, String title, String status, String subtitle, bool isUrgent) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Navega para os detalhes da planta, passando os dados necessários
        context.push(
          '/plant-details', 
        extra: {
          'name': title,
          'status': status,
          'lastWatered': subtitle,
          'isUrgent': isUrgent,
        });
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
              child: const Icon(Icons.park, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                  const SizedBox(height: 4),
                  Text(
                    status, 
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 14, 
                      color: isUrgent ? const Color(0xFFD9774B) : CERESColors.textMain, 
                    )
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
                  ]
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}