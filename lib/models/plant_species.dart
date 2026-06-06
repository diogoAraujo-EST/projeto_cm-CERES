class PlantSpecies {
  final String id;
  final String name;
  final String scientificName;
  final String imageUrl;
  final int defaultWateringInterval;
  final String lightLevel;
  final String description;
  final String careInstructions;

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

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    return PlantSpecies(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Planta',
      scientificName: json['scientific_name'] ?? 'Desconhecido',
      imageUrl: json['image_url'] ?? 'https://images.unsplash.com/photo-1545241047-6083a3684587?w=400',
      defaultWateringInterval: json['watering_interval'] ?? 7,
      lightLevel: json['light'] ?? 'Luz indireta',
      description: json['description'] ?? 'Sem descrição.',
      careInstructions: json['care'] ?? 'Rega regular.',
    );
  }
}