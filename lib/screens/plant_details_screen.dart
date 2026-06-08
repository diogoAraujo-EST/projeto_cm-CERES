import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../services/firestore_service.dart';
import '../models/user_plant.dart';
import '../models/room.dart';

class PlantDetailsScreen extends StatefulWidget {
  // --- OTIMIZAÇÃO DE ARQUITETURA ---
  // Recebemos o objeto da planta completo logo na navegação (State Transfer)!
  // Assim, quando o ecrã abre, não temos de fazer um novo pedido (fetch) ao Firebase
  // para ir buscar os detalhes. O ecrã abre instantaneamente com custo zero de rede.
  final UserPlant plant; 

  const PlantDetailsScreen({
    super.key,
    required this.plant,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  // --- ESTADO LOCAL (STATE MANAGEMENT) ---
  // Flags booleanas para mostrar rodinhas de loading nos botões certos e evitar duplo-clique acidental
  bool _isWatering = false;
  bool _isUploadingImage = false;
  
  // Guardamos o link da imagem atual no state local da página. 
  // Porquê? Se o utilizador tirar uma foto nova, queremos que a foto atualize no ecrã 
  // instantaneamente (Optimistic UI Update), sem ele ter de sair e voltar a entrar na página.
  late String _currentImageUrl;
  
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // A imagem inicial ao abrir o ecrã é a que veio guardada no objeto transferido pela navegação
    _currentImageUrl = widget.plant.imageUrl;
  }

  // --- MOTOR DE INTELIGÊNCIA (BUSINESS LOGIC) ---
  // Esta função é o "Cérebro" do nosso MVP. Em vez de mostrarmos apenas dados brutos da DB,
  // a app faz contas de cabeça para ajustar a rega e "explica" essas contas ao utilizador num 
  // texto amigável (Conversational UI), cruzando os dados biológicos da planta com as condições físicas da casa.
   String _getDynamicRecommendation(Room room) {
    String rec = '';
    bool adjusted = false; // Flag para sabermos se o algoritmo alterou os dias base ou não

    // 1. Condições de Exterior vs Interior
    if (room.isExterior) {
      rec += '🌤️ O espaço (${room.name}) é exterior. O sol e o vento secam a terra mais depressa.\n\n';
      adjusted = true;
    } else {
      rec += '🏠 A planta está no interior (${room.name}), onde a evaporação é mais controlada.\n\n';
    }

    // 2. Luz da API (Ideal) vs Luz da Divisão (Realidade)
    String pLight = widget.plant.apiLight.toLowerCase();
    String rLight = room.lightLevel.toLowerCase();

    // Se é uma planta de sol mas o quarto é escuro (Risco de apodrecimento das raízes)
    if (rLight == 'pouca luz' && (pLight.contains('muita') || pLight.contains('direta'))) {
      rec += '⚠️ Alerta de Luz: A planta prefere $pLight, mas a divisão tem $rLight. A fotossíntese será lenta, e a planta vai consumir água muito devagar. Para evitar apodrecer as raízes, o teu intervalo de rega foi aumentado.\n\n';
      adjusted = true;
    } 
    // Se é uma planta de sombra mas a varanda bate muito sol (Risco de secar)
    else if (rLight == 'muita luz' && (pLight.contains('pouca') || pLight.contains('indireta'))) {
      rec += '⚠️ Alerta de Luz: A planta prefere $pLight, mas a divisão tem $rLight. O excesso de sol vai secar a terra rapidamente. Para evitar que a planta seque, o teu intervalo de rega foi reduzido.\n\n';
      adjusted = true;
    } else {
      // O utilizador colocou a planta no local perfeito
      rec += '✅ Excelente! O nível de luz da divisão ($rLight) é perfeitamente adequado para as necessidades desta planta.\n\n';
    }

    // 3. Conclusão Final do Algoritmo gerada de forma dinâmica
    if (adjusted) {
      rec += '💡 O algoritmo CERES ajustou automaticamente a rega para cada ${widget.plant.wateringInterval} dias em vez do padrão da espécie!';
    } else {
      rec += '💡 A rega foi mantida no padrão ideal de ${widget.plant.wateringInterval} dias.';
    }

    return rec;
  }

  // --- LÓGICA DE ATUALIZAÇÃO DA FOTO (HARDWARE INTEGRATION) ---
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Fecha o menu inferior (BottomSheet) antes de abrir a câmara
    final picker = ImagePicker();
    try {
      // Abre a câmara ou a galeria.
      // OTIMIZAÇÃO: Limitamos a imageQuality a 70% e a largura a 800px. Isto é crucial
      // para não esgotar o limite gratuito de armazenamento (Firebase Storage) e para a app ser rápida.
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
      
      if (pickedFile != null) {
        setState(() => _isUploadingImage = true); // Escurece a foto do ecrã com um loading para dar feedback de sistema
        
        // Manda o novo ficheiro para a base de dados (Storage + Firestore update)
        final newUrl = await _firestoreService.updatePlantImage(widget.plant.id, File(pickedFile.path));
        
        // Se correu bem, atualizamos a foto no ecrã e desligamos o loading!
        setState(() { _currentImageUrl = newUrl; _isUploadingImage = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto atualizada!'), backgroundColor: CERESColors.primaryDarkGreen));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false); // Em caso de erro, desliga o loading para a app não encravar
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao atualizar foto.'), backgroundColor: Colors.red));
      }
    }
  }

  // O menu modal (BottomSheet) que interage com o Hardware do telemóvel
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text('Alterar foto da Planta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain))),
            ListTile(leading: const Icon(Icons.camera_alt, color: CERESColors.primaryDarkGreen), title: const Text('Tirar foto com a Câmara'), onTap: () => _pickImage(ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library, color: CERESColors.primaryDarkGreen), title: const Text('Escolher da Galeria'), onTap: () => _pickImage(ImageSource.gallery)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- ACÇÕES RÁPIDAS (DATABASE MUTATIONS) ---
  // Quando o utilizador clica na gota de água
  Future<void> _waterPlant() async {
    setState(() => _isWatering = true); // Transforma o botão numa rodinha para evitar cliques múltiplos
    try {
      // Dizemos à base de dados que a planta bebeu água agora (A Firebase trata dos timestamps)
      await _firestoreService.waterPlant(widget.plant.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('💧 Regaste a ${widget.plant.nickname}!'), backgroundColor: CERESColors.primaryDarkGreen, behavior: SnackBarBehavior.floating));
        // Voltamos ao ecrã anterior mal a rega termine, forçando a Home a renderizar os dados novos
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao regar planta.'), backgroundColor: Colors.red));
        setState(() => _isWatering = false);
      }
    }
  }

  // Deitar a planta fora (Delete record)
  Future<void> _deletePlant() async {
    try {
      await _firestoreService.deletePlant(widget.plant.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Planta eliminada.'), backgroundColor: Colors.red));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao eliminar planta.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // O corpo inteiro faz scroll para garantir suporte a ecrãs pequenos
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- COMPOSIÇÃO DE UI AVANÇADA (LAYERING) ---
            // Usamos Stack para conseguirmos meter os botões de voltar e de regar POR CIMA da foto da planta
            Stack(
              children: [
                
                // O bloco da imagem em si
                GestureDetector(
                  // Truque de UX: Pressionar a foto durante 1 segundo abre o menu para a trocar (evita cliques acidentais)
                  onLongPress: _showImageSourceDialog, 
                  child: Stack(
                    children: [
                      Container(
                        height: 350, width: double.infinity,
                        // Fallback de design: Fundo verde claro caso a foto atrase a carregar via rede
                        decoration: BoxDecoration(color: CERESColors.primaryDarkGreen.withValues(alpha: 0.08), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                          child: Image.network(_currentImageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.park, size: 150, color: CERESColors.primaryDarkGreen))),
                        ),
                      ),
                      
                      // Efeito sombreado por cima da foto enquanto faz upload de uma nova
                      if (_isUploadingImage)
                        Container(height: 350, width: double.infinity, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))), child: const Center(child: CircularProgressIndicator(color: Colors.white))),
                      
                      // O botãozinho flutuante de editar foto posicionado milimetricamente no canto inferior direito
                      if (!_isUploadingImage)
                        Positioned(bottom: 20, right: 20, child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)]), child: IconButton(icon: const Icon(Icons.add_a_photo, color: CERESColors.primaryDarkGreen, size: 22), onPressed: _showImageSourceDialog)))
                    ],
                  ),
                ),
                
                // --- BARRA DE TOPO FLUTUANTE ---
                // O SafeArea garante que estes botões não ficam escondidos debaixo da barra de bateria/relógio nativa do telemóvel
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        // Botão de voltar (Tem fundo branco e uma sombra pesada para ser legível mesmo se a foto da planta for muito escura/noite)
                        Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]), child: IconButton(icon: const Icon(Icons.arrow_back, color: CERESColors.textMain), onPressed: () => context.pop())),
                        const SizedBox(width: 12),
                        // Botão de Rega rápida
                        Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]), child: IconButton(icon: _isWatering ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.water_drop, color: Colors.blueAccent), onPressed: _isWatering ? null : _waterPlant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // --- CONTEÚDO PRINCIPAL ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // O Título (Nome da planta) e o botão de contexto (3 pontinhos)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.plant.nickname, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CERESColors.textMain))),
                      
                      // Dropdown Menu nativo e responsivo
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: CERESColors.textSecondary),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) { 
                          if (value == 'Eliminar') _deletePlant(); 
                          // O Editar e o Pausar são Mocks de UI para demonstrar a escalabilidade do sistema
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Editar', child: Text('Editar Planta')),
                          const PopupMenuItem(value: 'Pausar', child: Text('Pausar Regas')),
                          const PopupMenuDivider(), // Linha separadora antes das opções destrutivas
                          const PopupMenuItem(value: 'Eliminar', child: Text('Eliminar Planta', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // --- CARTÃO VISUAL DE ESTADO DA PLANTA ---
                  // Condição ternária para mudar toda a paleta do cartão: Laranja (Alerte/Sede) vs Verde (Saudável)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: widget.plant.isUrgent ? const Color(0xFFD9774B).withValues(alpha: 0.1) : CERESColors.primaryDarkGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop, color: widget.plant.isUrgent ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.plant.statusText, style: TextStyle(fontWeight: FontWeight.bold, color: widget.plant.isUrgent ? const Color(0xFFD9774B) : CERESColors.primaryDarkGreen)),
                            Text(widget.plant.lastWateredText, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // --- INFORMAÇÕES DA API (Read-only) ---
                  const Text('Sobre a planta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 16),
                  
                  // Componentização: Usamos um método auxiliar aqui para não poluir a árvore de Widgets (DRY Principle - Don't Repeat Yourself)
                  _buildDetailRow('Espécie', widget.plant.speciesName),
                  const Divider(color: Color(0xFFEEEEEE), height: 24),
                  _buildDetailRow('Luz Ideal', widget.plant.apiLight),
                  const Divider(color: Color(0xFFEEEEEE), height: 24),
                  _buildDetailRow('Descrição', widget.plant.apiDescription),
                  const Divider(color: Color(0xFFEEEEEE), height: 24),
                  _buildDetailRow('Dica', widget.plant.apiCare),
                  
                  const SizedBox(height: 32),
                  
                  // --- A EXPLICAÇÃO DO ALGORITMO (REACTIVE UI) ---
                  const Text('Recomendação de Rega', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                  const SizedBox(height: 8),
                  
                  // StreamBuilder: Ouve ativamente as mudanças nas Divisões da Casa.
                  // Vantagem: Se o utilizador tiver acabado de mudar a divisão de "interior" para "exterior" noutro ecrã,
                  // este texto de recomendação re-calcula-se e muda instantaneamente sozinho!
                  StreamBuilder<List<Room>>(
                    stream: _firestoreService.getUserRooms(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text('A analisar as condições...', style: TextStyle(color: Colors.grey));
                      
                      // Tenta encontrar na base de dados a divisão específica onde esta planta está associada
                      final room = snapshot.data!.firstWhere(
                        (r) => r.name == widget.plant.roomName, 
                        // Mecanismo de segurança (Fallback): Se a divisão tiver sido apagada, gera uma temporária na memória para a app não crashar (Null Safety)
                        orElse: () => Room(name: 'Desconhecido', lightLevel: 'Luz Média', isExterior: false)
                      );

                      // Alimenta a divisão encontrada ao cérebro do algoritmo
                      String customRec = _getDynamicRecommendation(room);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Text(customRec, style: const TextStyle(fontSize: 13, color: CERESColors.textSecondary, height: 1.5)),
                      );
                    }
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET AJUDANTE DE LAYOUT ---
  // Cria uma linha estruturada em grelha sem usar Tables complicadas.
  // Usa o Flexbox do Flutter (Expanded flex): flex 2 para os títulos (40% do ecrã), 
  // flex 3 para o conteúdo (60% do ecrã). Isto garante que nunca há overflow de texto.
  Widget _buildDetailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(title, style: const TextStyle(color: CERESColors.textSecondary, fontWeight: FontWeight.w500))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(color: CERESColors.textMain, fontWeight: FontWeight.w500, height: 1.4))),
      ],
    );
  }
}