// Este modelo representa as divisões da casa do utilizador.
// É através disto que a app descobre se a planta está no ambiente certo ou não!
class Room {
  
  // O nome amigável da divisão (ex: "Quarto", "Varanda da Cozinha")
  final String name;
  
  // Nível de iluminação configurado pelo utilizador quando cria a divisão.
  // Valores típicos: "Muita Luz", "Luz Média", "Pouca Luz".
  // Isto vai depois ser comparado com o 'lightLevel' ideal da PlantSpecies!
  final String lightLevel; 
  
  // Um fator decisivo para o intervalo de rega. 
  // Se for exterior (true), há vento e sol direto que secam a terra mais depressa, 
  // e o algoritmo rouba um dia ao intervalo de rega para evitar que a planta seque.
  final bool isExterior;

  // Construtor normal
  Room({
    required this.name,
    required this.lightLevel,
    required this.isExterior,
  });
}