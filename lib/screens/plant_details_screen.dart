import 'package:flutter/material.dart';

class PlantDetailsScreen extends StatelessWidget {

  final String plantName;
  final String plantStatus;

  const PlantDetailsScreen({
    super.key, 
    required this.plantName,
    required this.plantStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalhes da Planta'),
        backgroundColor: Colors.green, // Cor básica
        elevation: 0,
        //o flutter adiciona uma seta para voltar attrás autoamticamente!!!
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // imagem temp
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Icon(Icons.park, size: 100, color: Colors.green),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plantName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  //estado da rega
                  Container(
                    padding: const EdgeInsets.all(15),
                    color: Colors.orange.shade100,
                    child: Row(
                      children: [
                        const Icon(Icons.water_drop, color: Colors.orange),
                        const SizedBox(width: 10),
                        Text(
                          plantStatus,
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  const Text('Sobre a planta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  // Textos descritivos
                  const Text('Tipo: Interior', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  const Text('Luz: Luz indireta', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),
                  const Text('Frequência de rega: A cada 3 dias', style: TextStyle(fontSize: 16)),
                  
                  const SizedBox(height: 40),
                  
                  // Botão de Regar 
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.water_drop, color: Colors.white),
                      label: const Text('REGAR AGORA', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        print("A planta $plantName foi regada!"); 
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Planta regada!')),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}