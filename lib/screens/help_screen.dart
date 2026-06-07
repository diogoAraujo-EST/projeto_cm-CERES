import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';

// Como este ecrã é apenas para mostrar texto estático (não há variáveis a mudar, 
// nem botões de loading, nem ligações diretas a bases de dados em tempo real), 
// usamos um StatelessWidget. É mais leve para o telemóvel e consome menos recursos!
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // Cabeçalho standard da app
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // context.pop() é a forma do GoRouter dizer "volta para onde estavas antes"
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop()),
        title: const Text('Ajuda e Suporte', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
      ),
      
      // Usamos uma ListView em vez de uma Column. Porquê?
      // Porque se no futuro decidirmos adicionar 20 perguntas frequentes, 
      // a ListView ganha a barra de scroll automaticamente e o ecrã não "quebra" em telemóveis mais pequenos.
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('Perguntas Frequentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
          SizedBox(height: 16),
          
          // --- EXPANSION TILES ---
          // O ExpansionTile é um daqueles widgets "salva-vidas" do Flutter. 
          // Ele cria sozinho aquele efeito de acordeão (clicas e ele abre para baixo).
          // Já traz a setinha de lado e as animações todas de borla, sem termos de escrever lógica extra!
          
          ExpansionTile(
            title: Text('Como adiciono uma planta?'), 
            children: [
              // Colocamos um Padding dentro dos children para a resposta não ficar colada às margens
              Padding(
                padding: EdgeInsets.all(16.0), 
                child: Text('No ecrã inicial, clica no botão verde com o símbolo "+" no canto inferior direito.')
              )
            ]
          ),
          
          ExpansionTile(
            title: Text('Como sei que devo regar?'), 
            children: [
              Padding(
                padding: EdgeInsets.all(16.0), 
                child: Text('A planta vai aparecer a Laranja no ecrã Inicial a dizer "Precisa de rega".')
              )
            ]
          ),
          
        ],
      ),
    );
  }
}