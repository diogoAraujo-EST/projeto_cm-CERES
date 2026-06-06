class Room {
  final String name;
  final String lightLevel; // "Muita Luz", "Luz Média", "Pouca Luz"
  final bool isExterior;

  Room({
    required this.name,
    required this.lightLevel,
    required this.isExterior,
  });
}