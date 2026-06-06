import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plant_species.dart';

class PlantApiService {
  
  final String _apiUrl = 'https://gist.githubusercontent.com/GoncaloFR-Edu/97c1d869061ce56ca25ce6d8f33cae5d/raw/23ebe0144e442ccea8acc97a2e7620eedf65b2f1/plantas_api.json';

  Future<List<PlantSpecies>> fetchSpecies({String query = ''}) async {
    try {
      // Faz o pedido HTTP à sua própria API Externa (Gist)
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        // Descodifica o JSON tendo em atenção caracteres portugueses (utf8)
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List<PlantSpecies> allPlants = data.map((json) => PlantSpecies.fromJson(json)).toList();

        if (query.isEmpty) {
          return allPlants; // Retorna tudo se não houver pesquisa
        }

        // Filtra a pesquisa pelo nome ou nome científico
        final searchLower = query.toLowerCase();
        return allPlants.where((plant) {
          return plant.name.toLowerCase().contains(searchLower) ||
                 plant.scientificName.toLowerCase().contains(searchLower);
        }).toList();

      } else {
        throw Exception('Erro ao carregar a sua API Externa');
      }
    } catch (e) {
      print('Erro de API: $e');
      return [];
    }
  }
}