import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  double _frequency = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Adicionar Planta', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CERESColors.textMain),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: CERESColors.primaryDarkGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Icon(Icons.park, size: 60, color: CERESColors.primaryDarkGreen)),
            ),
            const SizedBox(height: 32),
            
            const Text('Nome da Planta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ex: A minha Monstera',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: CERESColors.primaryDarkGreen, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Frequência de Rega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
            const SizedBox(height: 8),
            Text(
              'Regar a cada ${_frequency.toInt()} dias', 
              style: const TextStyle(fontSize: 18, color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Slider(
              value: _frequency,
              min: 1,
              max: 15,
              divisions: 14,
              activeColor: CERESColors.primaryDarkGreen,
              inactiveColor: CERESColors.primaryDarkGreen.withValues(alpha: 0.2),
              onChanged: (val) {
                setState(() {
                  _frequency = val;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🌿 Planta adicionada com sucesso!'),
                                  backgroundColor: CERESColors.primaryDarkGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                  context.pop(); // Volta à home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CERESColors.primaryDarkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Guardar Planta', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}