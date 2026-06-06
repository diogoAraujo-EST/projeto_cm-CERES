import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
        title: const Text('Ajuda e Suporte', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('Perguntas Frequentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          SizedBox(height: 16),
          ExpansionTile(title: Text('Como adiciono uma planta?'), children: [Padding(padding: EdgeInsets.all(16.0), child: Text('No ecrã inicial, clica no botão verde com o símbolo "+" no canto inferior direito.'))]),
          ExpansionTile(title: Text('Como sei que devo regar?'), children: [Padding(padding: EdgeInsets.all(16.0), child: Text('A planta vai aparecer a Laranja no ecrã Inicial a dizer "Precisa de rega".'))]),
        ],
      ),
    );
  }
}