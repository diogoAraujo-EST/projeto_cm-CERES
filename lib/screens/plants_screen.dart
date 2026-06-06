import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Barra de pesquisa a ser implementada...')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildPlantItem(context, 'Monstera', 'Interior • Luz indireta'),
          const SizedBox(height: 16),
          _buildPlantItem(context, 'Ficus Lyrata', 'Interior • Luz brilhante'),
          const SizedBox(height: 16),
          _buildPlantItem(context, 'Samambaia', 'Interior • Sombra parcial'),
          const SizedBox(height: 16),
          _buildPlantItem(context, 'Suculenta', 'Exterior • Luz direta'),
          
          const SizedBox(height: 80), // Espaço para não bater no botão flutuante da navbar
        ],
      ),
    );
  }

  Widget _buildPlantItem(BuildContext context, String name, String details) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Aproveitamos a rota que já criaste para abrir os detalhes!
        context.push('/plant-details', extra: {
          'name': name,
          'status': 'Sem rega urgente',
          'lastWatered': 'Última rega: Há 2 dias',
          'isUrgent': false,
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
              child: const Icon(Icons.park, color: CERESColors.primaryDarkGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                  const SizedBox(height: 4),
                  Text(details, style: const TextStyle(fontSize: 13, color: CERESColors.textSecondary)),
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