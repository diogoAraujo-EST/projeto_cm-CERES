import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';

// É um StatelessWidget porque não precisamos de guardar estados (como caixas de texto ou loadings manuais).
// A lista desenha-se sozinha à medida que os dados vão caindo do Firebase.
class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A nossa ligação ao serviço da base de dados
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      
      // --- CABEÇALHO ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('As Minhas Plantas', style: TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.bold)),
        centerTitle: true,
/*         actions: [
          // Botão de pesquisa
          IconButton(
            icon: const Icon(Icons.search, color: CERESColors.textMain),
            onPressed: () {
              // Como a pesquisa ainda não está feita, mostramos um aviso simpático 
              // em vez de deixar um botão partido que não faz nada!
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barra de pesquisa a ser implementada...')));
            },
          ),
        ], */
      ),
      
      // --- CORPO DA PÁGINA (A LISTA VIVA) ---
      // O StreamBuilder substitui as antigas listas fixas. Fica constantemente à escuta.
      // Se apagares uma planta noutro ecrã, ela desaparece daqui instantaneamente!
      body: StreamBuilder<List<UserPlant>>(
        stream: firestoreService.getUserPlants(),
        builder: (context, snapshot) {
          
          // 1. A carregar dados pela primeira vez
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          // 2. Se a internet falhar ou der algum erro bizarro
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar as plantas.', style: TextStyle(color: Colors.red)));
          }

          final plants = snapshot.data ?? [];

          // 3. O estado vazio (Empty State). É essencial para a boa experiência do utilizador
          // não ficar a olhar para um ecrã branco a achar que a app bloqueou.
          if (plants.isEmpty) {
            return const Center(
              child: Text('Ainda não tens plantas guardadas.', style: TextStyle(color: CERESColors.textSecondary, fontSize: 16)),
            );
          }

          // 4. Sucesso! Desenha a lista de plantas
          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildPlantItem(context, plant),
              );
            },
          );
        },
      ),
    );
  }

  // --- O CARTÃO DE CADA PLANTA ---
  // Extraímos isto para uma função à parte para o bloco de cima (ListView.builder) não ficar gigante
  Widget _buildPlantItem(BuildContext context, UserPlant plant) {
    // InkWell dá-nos o efeito de "clique" padrão do Material Design (aquela ondinha cinzenta)
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Quando clicamos, abrimos o ecrã de detalhes.
        // O "extra: plant" leva a planta inteira na mochila, para o próximo ecrã não ter de a transferir de novo!
        context.push('/plant-details', extra: plant);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Sombra super levezinha para o cartão saltar do fundo branco da página
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            
            // A imagem da planta (quadradinho à esquerda)
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              // ClipRRect é necessário porque a imagem normal é quadrada de cantos vivos, 
              // e nós queremos que ela respeite os cantos redondos do contentor!
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  plant.imageUrl,
                  fit: BoxFit.cover,
                  // Fallback: se o link da foto estiver quebrado, desenhamos uma árvore genérica
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.park, color: CERESColors.primaryDarkGreen),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Zona de texto do meio (Expanded empurra a setinha lá para o fundo à direita)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                  const SizedBox(height: 4),
                  
                  // Detalhes extras: onde ela está e que espécie é
                  // O maxLines: 1 e overflow limitam o texto a uma linha. Se for muito grande mete "..." no fim!
                  Text('${plant.roomName} • ${plant.speciesName}', style: const TextStyle(fontSize: 13, color: CERESColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            
            // A setinha para indicar que este cartão é clicável
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}