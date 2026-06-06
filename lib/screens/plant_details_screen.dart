import 'package:flutter/material.dart';
import '../constants/colors.dart';

class PlantDetailsScreen extends StatelessWidget {
  final String plantName;
  final String plantStatus;
  final String lastWatered;
  final bool isUrgent;

  const PlantDetailsScreen({
    super.key,
    required this.plantName,
    required this.plantStatus,
    required this.lastWatered,
    required this.isUrgent,
  });

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
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: CERESColors.primaryDarkGreen.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.park, size: 150, color: CERESColors.primaryDarkGreen),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: CERESColors.textMain),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.water_drop, color: Colors.blueAccent),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('💧 Regaste a $plantName!'),
                                  backgroundColor: CERESColors.primaryDarkGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
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
                      Text(plantName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: CERESColors.textSecondary),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ação selecionada: $value')),
                          );
                        },
                        itemBuilder: (BuildContext context) => [
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
                      color: isUrgent ? const Color(0xFFD9774B).withValues(alpha: 0.1) : CERESColors.primaryDarkGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop, color: isUrgent ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plantStatus, style: TextStyle(fontWeight: FontWeight.bold, color: isUrgent ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen)),
                            if (lastWatered.isNotEmpty)
                              Text(lastWatered, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Sobre a planta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Tipo', 'Interior'),
                  const Divider(color: Color(0xFFEEEEEE), height: 30),
                  _buildDetailRow('Luz', 'Luz indireta brilhante'),
                  const Divider(color: Color(0xFFEEEEEE), height: 30),
                  _buildDetailRow('Temperatura ideal', '18–27 °C'),
                  const Divider(color: Color(0xFFEEEEEE), height: 30),
                  _buildDetailRow('Humidade ideal', '50–70%'),
                  const SizedBox(height: 32),
                  const Text('Frequência de rega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 8),
                  const Text('A cada 3–4 dias', style: TextStyle(fontSize: 14, color: CERESColors.textMain, fontWeight: FontWeight.w600)),
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