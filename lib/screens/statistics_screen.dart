import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const Text(
            'Estatísticas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // "Abas" Falsas Mockup)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('Semana', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text('Mês', style: TextStyle(color: Colors.grey.shade600)),
                Text('Ano', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Secção do Gráfico
          const Text('Regas realizadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('12 esta semana', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // Conteiners para fazer barras falsas
          Container(
            height: 150,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFakeBar(40, 'Seg'),
                _buildFakeBar(80, 'Ter'),
                _buildFakeBar(60, 'Qua'),
                _buildFakeBar(109, 'Qui'),
                _buildFakeBar(90, 'Sex'),
                _buildFakeBar(30, 'Sáb'),
                _buildFakeBar(70, 'Dom'),
              ],
            ),
          ),
          
          const SizedBox(height: 30),

          // Planta mais regada hardcoded
          const Text('Planta mais regada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: const EdgeInsets.all(10),
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.park, color: Colors.green, size: 40),
            title: const Text('Samambaia', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('3 regas'),
          ),

          const SizedBox(height: 30),

          // Consistência
          const Text('Consistência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ótimo!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 5),
                      Text('Manténs uma ótima rotina de rega.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                // Gráfico circular
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: 0.9, // 90%
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.green,
                        strokeWidth: 8,
                      ),
                    ),
                    const Text('90%', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Função auxiliar para a barra do gráfico falsa
  Widget _buildFakeBar(double height, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: height,
          decoration: const BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}