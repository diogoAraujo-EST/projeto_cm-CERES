// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Header Simples
          const Text(
            'Olá, Mariana!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Aqui está o resumo das tuas plantas.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // Título da secção
          const Text('Hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Alerta básico
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue),
                SizedBox(width: 10),
                Text('2 plantas precisam de rega'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // cartão2
          _buildBasicPlantCard('Monstera', 'Precisa de rega', 'Última rega: há 2 dias', true),
          const SizedBox(height: 10),
          _buildBasicPlantCard('Ficus Lyrata', 'Precisa de rega', 'Última rega: há 1 dia', true),

          const SizedBox(height: 30),
          const Text('Próximas regas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // cartão1
          _buildBasicPlantCard('Samambaia', 'Amanhã', '', false),
          const SizedBox(height: 10),
          _buildBasicPlantCard('Suculenta', 'Em 2 dias', '', false),
        ],
      ),
    );
  }

  Widget _buildBasicPlantCard(String title, String status, String subtitle, bool isUrgent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.image, size: 50, color: Colors.grey), 
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                status, 
                style: TextStyle(color: isUrgent ? Colors.orange : Colors.black),
              ),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}