// Este modelo representa a informação "geral" de uma espécie (A enciclopédia).
// Não se refere à planta específica que o utilizador tem em casa (essa é a UserPlant).
class PlantSpecies {
  // Declaramos tudo como "final" (imutável) porque a informação da enciclopédia
  // não deve ser alterada a meio do caminho pela app.
  final String id;
  final String name;
  final String scientificName;
  final String imageUrl;
  final int defaultWateringInterval; // O intervalo de dias "ideal" base para regar esta espécie
  final String lightLevel;
  final String description;
  final String careInstructions;

  // Construtor normal
  const PlantSpecies({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.imageUrl,
    required this.defaultWateringInterval,
    required this.lightLevel,
    required this.description,
    required this.careInstructions,
  });

  // --- O TRADUTOR DA INTERNET ---
  // A "factory" é uma função construtora especial. Ela pega no dicionário bruto (Map) 
  // que recebemos do JSON da API e converte-o nesta classe bonitinha.
  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    return PlantSpecies(
      // A internet pode falhar, um campo pode vir vazio no JSON, ou o programador do backend (tu)
      // pode ter-se esquecido de preencher algo. 
      // Por isso, usamos o "??" (rede de segurança): "Se o lado esquerdo for nulo, usa o lado direito".
      
      id: json['id']?.toString() ?? '', // Força o ID a ser String, mesmo que no JSON seja um número
      name: json['name'] ?? 'Planta',
      scientificName: json['scientific_name'] ?? 'Desconhecido',
      
      // Se não houver link de foto para esta espécie, espetamos logo uma foto de fallback bonita do Unsplash
      imageUrl: json['image_url'] ?? 'https://images.unsplash.com/photo-1545241047-6083a3684587?w=400',
      
      defaultWateringInterval: json['watering_interval'] ?? 7, // Na dúvida, rega de semana a semana!
      lightLevel: json['light'] ?? 'Luz indireta',
      description: json['description'] ?? 'Sem descrição.',
      careInstructions: json['care'] ?? 'Rega regular.',
    );
  }
}