import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../models/user_plant.dart';
import '../services/firestore_service.dart';
import '../services/weather_service.dart'; // O novo serviço de meteorologia que criaste!
import 'package:geolocator/geolocator.dart';

// Este ecrã é um StatelessWidget porque nós não precisamos de gerir o estado "à mão" com setStates.
// O StreamBuilder (mais abaixo) faz o trabalho todo de atualizar o ecrã sozinho sempre que o Firebase muda!
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Vamos buscar quem está logado e preparamos a ponte para a base de dados
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    // --- LÓGICA DO NOME DO UTILIZADOR ---
    String displayName = 'Utilizador';
    if (user != null) {
      if (user.isAnonymous) {
        // Se entrou sem conta, chamamos-lhe apenas Convidado
        displayName = 'Convidado';
      } else if (user.displayName != null && user.displayName!.isNotEmpty) {
        // Truque de segurança visual: Se o utilizador tiver um nome gigante (ex: "José Maria de Albuquerque..."),
        // nós cortamos aos 20 caracteres para não partir o design do cabeçalho lá em cima!
        displayName = user.displayName!.length > 20 
            ? user.displayName!.substring(0, 20) 
            : user.displayName!;
      }
    }

    return SafeArea(
      // 1. O CORAÇÃO DO ECRÃ: O STREAMBUILDER
      // Ao metermos o StreamBuilder aqui logo no topo, toda a página fica "viva". 
      // Se regares uma planta noutro telemóvel, este ecrã atualiza num piscar de olhos.
      child: StreamBuilder<List<UserPlant>>(
        stream: firestoreService.getUserPlants(),
        builder: (context, snapshot) {
          
          // O tal truque do smoothness: só mostramos o loading se estiver à espera E não houver dados antigos
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar as plantas.', style: TextStyle(color: Colors.red)));
          }

          final plants = snapshot.data ?? [];
          
          // 2. SEPARAÇÃO DAS ÁGUAS (LITERALMENTE)
          // Fazemos a matemática logo aqui no topo para podermos usar estas duas listas em qualquer lado do ecrã
          final urgentPlants = plants.where((p) => p.isUrgent).toList(); // As que estão cheias de sede
          final upcomingPlants = plants.where((p) => !p.isUrgent).toList(); // As que estão bem

          return Column(
            children: [
              // --- CABEÇALHO (Saudação e Sino) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Olá, $displayName!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                            const SizedBox(width: 4),
                            // Puxamos o logotipo um bocadinho para cima com o Transform para alinhar visualmente com o texto
                            Transform.translate(
                              offset: const Offset(0, -5),
                              child: Image.asset('assets/images/ceres_logo_only_2.png', height: 30),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Aqui está o resumo das tuas plantas.', style: TextStyle(fontSize: 14, color: CERESColors.textSecondary)),
                      ],
                    ),
                    
                    // --- SINO DE NOTIFICAÇÕES ---
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                      child: IconButton(
                        // O Badge é espetacular: põe a bolinha vermelha no ícone automaticamente!
                        icon: Badge(
                          // A bolinha só aparece se a lista de "urgentPlants" não estiver vazia
                          isLabelVisible: urgentPlants.isNotEmpty, 
                          label: Text('${urgentPlants.length}'), 
                          backgroundColor: CERESColors.alertOrange,
                          child: const Icon(Icons.notifications_none, color: CERESColors.textMain),
                        ),
                        onPressed: () {
                          context.push('/notifications');
                        },
                      ),
                    )
                  ],
                ),
              ),
              
              // --- ALERTA METEOROLÓGICO DA API EXTERNA ---
              // Colocaste logo abaixo do cabeçalho. Boa escolha de UI! É onde os olhos do utilizador caem primeiro.
              const WeatherBanner(),
              
              // --- CORPO PRINCIPAL ---
              Expanded(
                // Se o utilizador não tiver plantas nenhumas, mostramos um "Empty State" apelativo
                child: plants.isEmpty 
                ? Center( 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.park_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Ainda não tens plantas.', style: TextStyle(fontSize: 18, color: CERESColors.textSecondary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/add-plant'),
                          child: const Text('Adicionar a minha primeira planta', style: TextStyle(color: CERESColors.primaryDarkGreen, fontSize: 16)),
                        )
                      ],
                    ),
                  )
                // Se ele tiver plantas, desenhamos a lista!
                : ListView( 
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    children: [
                      const SizedBox(height: 24),

                      const Text('Hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                      const SizedBox(height: 16),                    
                      
                      // --- CAIXA DE ALERTA AZUL ---
                      // Mostra um resumo para ele não ter de contar as plantas uma a uma
                      if (urgentPlants.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.lightBlue, size: 28),
                              const SizedBox(width: 16),
                              Text('${urgentPlants.length} plantas precisam de rega', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: CERESColors.textMain)),
                            ],
                          ),
                        ),

                      // Reforço positivo: Se não houver regas pendentes, damos-lhe os parabéns
                      if (urgentPlants.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Tudo regado para hoje! 🎉', style: TextStyle(color: CERESColors.textSecondary)),
                        ),

                      // Despeja as plantas urgentes aqui (usamos o ... (spread operator) para desembrulhar a lista de widgets para dentro do ListView)
                      ...urgentPlants.map((plant) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildPlantCard(context, plant),
                      )),
                      
                      const SizedBox(height: 32),
                      
                      const Text('Próximas regas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                      const SizedBox(height: 16),

                      if (upcomingPlants.isEmpty)
                        const Text('Não tens regas agendadas.', style: TextStyle(color: CERESColors.textSecondary)),

                      // Despeja as plantas que ainda estão tranquilas
                      ...upcomingPlants.map((plant) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildPlantCard(context, plant),
                      )),
                      
                      const SizedBox(height: 80), // Espaço extra no fundo para não colidirem com a barra de navegação principal da app
                    ],
                  ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- COMPONENTE DO CARTÃO DA PLANTA ---
  Widget _buildPlantCard(BuildContext context, UserPlant plant) {
    // InkWell é como um GestureDetector, mas já vem com aquele efeito visual de "onda" (ripple) 
    // típico do Material Design quando clicamos
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Passamos o objeto `plant` inteiro pelo GoRouter para o ecrã de detalhes.
        // Assim o outro ecrã já tem os dados todos e não precisa de ir à internet pedi-los de novo!
        context.push('/plant-details', extra: plant);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // A foto da planta em miniatura
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  plant.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.park, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CERESColors.textMain)),
                  const SizedBox(height: 4),
                  
                  // O texto do estado (ex: "Precisa de rega" ou "Tudo bem")
                  Text(
                    plant.statusText, 
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 14, 
                      // Se for urgente, pintamos de laranja para chamar a atenção logo no cartão
                      color: plant.isUrgent ? CERESColors.alertOrange : CERESColors.textMain, 
                    )
                  ),
                  const SizedBox(height: 4),
                  // Aquele texto pequenino que diz há quantos dias foi a última rega
                  Text(plant.lastWateredText, style: const TextStyle(fontSize: 12, color: CERESColors.textSecondary)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- WIDGET INTELIGENTE DA METEOROLOGIA ---
// Criaste um widget separado (Stateful) para a meteorologia. Foi uma decisão arquitetural brilhante,
// porque assim o pedido à API do tempo é isolado e não bloqueia nem atrasa o ecrã inteiro de carregar as plantas!
class WeatherBanner extends StatefulWidget {
  const WeatherBanner({super.key});

  @override
  State<WeatherBanner> createState() => _WeatherBannerState();
}

class _WeatherBannerState extends State<WeatherBanner> {
  // A ligação ao teu novo serviço
  final _weatherService = WeatherService();
  
  // Guardamos o Future aqui (e não dentro do build) para garantir que 
  // o pedido à API só é feito uma vez quando o widget é criado, poupando dados móveis.
  late Future<String?> _weatherFuture;

  @override
  void initState() {
    super.initState();
    // Inicia a pesquisa pela meteorologia logo que este bloco verdece na memória
    _weatherFuture = _weatherService.getWeatherAlert();
  }

  // --- TRATAMENTO DE ERROS DE PERMISSÃO ---
  // Se o utilizador disser "Sim, podes usar a minha localização", 
  // nós disparamos a pesquisa outra vez para atualizar o ecrã instantaneamente.
  void _retryPermission() {
    setState(() {
      _weatherFuture = _weatherService.getWeatherAlert();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        // Enquanto o GPS está a tentar encontrar a pessoa ou a API está a pensar...
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Devolvemos uma caixa vazia (SizedBox.shrink) em vez de um "loading" 
          // para a app não ficar a piscar por todos os lados.
          return const SizedBox.shrink(); 
        }

        final data = snapshot.data;

        // --- CENA DO GPS (A PARTE CHATA) ---
        // O utilizador pode ter o GPS desligado no telemóvel, ou ter recusado a permissão na app.
        // Em vez de crasharmos a app, mostramos um aviso cinzento simpático a pedir para ligar.
        if (data == 'PERMISSION_DENIED' || data == 'LOCATION_DISABLED' || data == 'DENIED_FOREVER') {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_off_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        // Mudamos o texto consoante o tipo de problema que ocorreu
                        data == 'LOCATION_DISABLED' 
                          ? 'O GPS do telemóvel está desligado.' 
                          : 'Para receberes alertas meteorológicos para as tuas plantas, precisamos da tua localização.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // O BOTÃO DE RESOLVER O PROBLEMA
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Se o utilizador bloqueou para sempre (disse "Não e não voltes a perguntar"), 
                      // o Geolocator não consegue mostrar o popup. Temos de o mandar para as Definições do telemóvel!
                      if (data == 'DENIED_FOREVER') {
                        await Geolocator.openAppSettings();
                      } else if (data == 'LOCATION_DISABLED') {
                        // Manda ligar a "Localização" nas definições rápidas do Android
                        await Geolocator.openLocationSettings();
                      } else {
                        // Se for só uma negação simples, tenta pedir outra vez
                        _retryPermission();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CERESColors.primaryDarkGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Permitir Acesso', style: TextStyle(color: CERESColors.primaryDarkGreen, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        }

        // --- CENA DO TEMPO (SUCESSO) ---
        // Temos a localização, falámos com a API e descobrimos que vai chover muito ou fazer bué sol!
        if (data != null && data.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50, // Fundo laranjinha estilo "Aviso"
              border: Border.all(color: Colors.amber.shade200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_cloudy_outlined, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(data, style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          );
        }

        // Se estiver um tempo perfeitamente normal (ex: "Céu limpo, 20 graus"), 
        // a tua API não devolve nada (data é vazio) e este widget simplesmente "encolhe-se"
        // e desaparece silenciosamente para não chatear o utilizador com informações inúteis.
        return const SizedBox.shrink();
      },
    );
  }
}