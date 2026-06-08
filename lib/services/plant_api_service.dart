import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plant_species.dart';

import 'package:flutter/foundation.dart';

// O nosso "Mensageiro" da API
// Este ficheiro foca-se exclusivamente em ir à net buscar o catálogo mestre de plantas
class PlantApiService {
  
  // Como as APIs de plantas famosas são pagas, a solução genial aqui foi alojar 
  // um ficheiro JSON gigante no GitHub (Gist) e usá-lo como a nossa API gratuita!
  final String _apiUrl = 'https://gist.githubusercontent.com/GoncaloFR-Edu/97c1d869061ce56ca25ce6d8f33cae5d/raw/46fc3c175d2db1d4867d397f9f1f65a73bbdd3f6/plantas_api.json';

  // --- BUSCAR ESPÉCIES ---
  // A query é opcional. Se ninguém escrever nada, a query é uma string vazia ''
  Future<List<PlantSpecies>> fetchSpecies({String query = ''}) async {
    try {
      // 1. Faz o pedido HTTP à sua própria API Externa (Gist)
      // O programa fica à espera ("await") que a internet responda antes de avançar
      final response = await http.get(Uri.parse(_apiUrl));

      // Se a resposta for 200, significa "OK" no protocolo da Internet
      if (response.statusCode == 200) {
        
        // 2. A PARTE DO TEXTO (UTF-8)
        // O json.decode normal às vezes destrói os acentos (ex: "Água" fica "Ã¡gua").
        // O utf8.decode garante que os caracteres em português não se partem!
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        
        // 3. O MAPA (TRADUÇÃO)
        // Transformamos a lista de texto bruto do JSON numa lista limpa e bonita 
        // de objetos PlantSpecies (Dart)
        final List<PlantSpecies> allPlants = data.map((json) => PlantSpecies.fromJson(json)).toList();

        // Se a pessoa só abriu o ecrã e não procurou por planta nenhuma, 
        // mandamos logo o catálogo inteiro para desenhar o carrossel.
        if (query.isEmpty) {
          return allPlants; 
        }

        // 4. LÓGICA DE PESQUISA (FILTRO)
        // Passamos o que a pessoa escreveu para letras minúsculas (toLowerCase)
        // para que "Monstera" e "monstera" dêem o mesmo resultado.
        final searchLower = query.toLowerCase();
        
        // Retornamos apenas as plantas onde o nome (ou o nome científico) tem
        // as letras que a pessoa escreveu!
        return allPlants.where((plant) {
          return plant.name.toLowerCase().contains(searchLower) ||
                 plant.scientificName.toLowerCase().contains(searchLower);
        }).toList();

      } else {
        // Se der erro 404, 500, etc... atiramos uma excepção para o catch apanhar
        throw Exception('Erro ao carregar a sua API Externa');
      }
    } catch (e) {
      // Em caso de falta de internet ou link quebrado, protegemos a app
      // não a deixando crashar. Devolvemos só uma lista vazia [] para o ecrã tratar
      // e escrevemos o erro na consola para os developers (nós) vermos.
      debugPrint('Erro de API: $e');
      return [];
    }
  }
}