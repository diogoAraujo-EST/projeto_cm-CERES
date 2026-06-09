import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../models/user_plant.dart';
import '../services/firestore_service.dart';
import '../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';

// Este ecrã é um StatelessWidget porque nós não precisamos de gerir o estado "à mão" com setStates.
// Todo o ecrã reage passivamente às mudanças que vêm diretamente das bases de dados em tempo real.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Vamos buscar a "impressão digital" de quem está logado e preparamos a ponte para a base de dados
    final user = FirebaseAuth.instance.currentUser;
    final firestoreService = FirestoreService();

    return SafeArea(
      // --- O CORAÇÃO DO ECRÃ: STREAM DE PLANTAS ---
      // Mantém a lista de plantas sempre atualizada ao segundo.
      child: StreamBuilder<List<UserPlant>>(
        stream: firestoreService.getUserPlants(),
        builder: (context, snapshot) {
          
          // Prevenção de "flickering" (piscar do ecrã): só mostra a rodinha se não houver mesmo dados em cache
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: CERESColors.primaryDarkGreen));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar as plantas.', style: TextStyle(color: Colors.red)));
          }

          final plants = snapshot.data ?? [];
          
          // SEPARAÇÃO DAS ÁGUAS: Calculamos logo no topo quem tem sede e quem está saudável
          final urgentPlants = plants.where((p) => p.isUrgent).toList();
          final upcomingPlants = plants.where((p) => !p.isUrgent).toList();

          return Column(
            children: [
              // --- CABEÇALHO SUPERIOR ---
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // Alinha os blocos pelo topo
                  children: [
                    
                    // --- ÁREA DA SAUDAÇÃO (REATIVA) ---
                    // O EXPANDED é vital aqui: diz ao texto que ele só pode crescer até onde não chocar com o sino!
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // O FLEXIBLE permite que o texto encolha de forma inteligente caso o ecrã seja pequeno
                              Flexible(
                                // A MÁGICA: O STREAMBUILDER AGORA FICA SEMPRE À ESCUTA DO PERFIL DO UTILIZADOR!
                                // Se ele mudar de nome noutro ecrã, isto atualiza instantaneamente.
                                child: StreamBuilder<DocumentSnapshot>(
                                  stream: firestoreService.getUserProfile(),
                                  builder: (context, userSnapshot) {
                                    String finalName = 'Utilizador'; // Valor por defeito
                                    
                                    // 1. É uma conta sem registo?
                                    if (user?.isAnonymous ?? true) {
                                      finalName = 'Convidado';
                                    } 
                                    // 2. Temos dados frescos da base de dados Firestore?
                                    else if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                      final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                                      
                                      // Vai buscar a chave "name" e garante que não está em branco
                                      if (data != null && data.containsKey('name') && data['name'].toString().trim().isNotEmpty) {
                                        finalName = data['name'];
                                      } 
                                      // Se falhar o nome da base de dados, tenta usar o que está na conta Google/Auth
                                      else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
                                        finalName = user!.displayName!;
                                      }
                                    } 
                                    // 3. Fallback de segurança (Auth puro)
                                    else if (user?.displayName != null && user!.displayName!.isNotEmpty) {
                                      finalName = user!.displayName!;
                                    }
                                    
                                    return Text(
                                      'Olá, $finalName!', 
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CERESColors.textMain),
                                      // Proteção de Interface: Se o utilizador se chamar "José Maria de Albuquerque...",
                                      // a app corta o texto e mete "..." em vez de partir o layout do cabeçalho todo!
                                      overflow: TextOverflow.ellipsis, 
                                      maxLines: 1,
                                    );
                                  }
                                ),
                              ),
                              
                              const SizedBox(width: 4),
                              // Ajuste ótico (pixel-perfect) para alinhar a folha com a altura do texto
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
                    ),
                    
                    const SizedBox(width: 16), // Espaço de segurança inquebrável entre o texto e o sino
                    
                    // --- SINO DE NOTIFICAÇÕES (REATIVO) ---
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                      child: IconButton(
                        // O Badge deteta automaticamente se a lista urgentPlants tem plantas e desenha a bolinha
                        icon: Badge(
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
              
              // --- ALERTA METEOROLÓGICO INDEPENDENTE ---
              const WeatherBanner(),
              
              // --- CORPO PRINCIPAL (LISTA DAS PLANTAS) ---
              Expanded(
                child: plants.isEmpty 
                // EMPTY STATE: Design atencioso para quando o utilizador acaba de criar conta
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
                // LISTA POPULADA
                : ListView( 
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    children: [
                      const SizedBox(height: 24),

                      const Text('Hoje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                      const SizedBox(height: 16),                    
                      
                      // CAIXA AZUL: Resumo rápido das regas atrasadas
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

                      // REFORÇO POSITIVO: Gamification - dá os parabéns se a pessoa tiver tudo em dia
                      if (urgentPlants.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                          child: const Text('Tudo regado para hoje! 🎉', style: TextStyle(color: CERESColors.textSecondary)),
                        ),

                      // Usa o Spread Operator (...) para injetar a lista de widgets das plantas urgentes diretamente no ListView
                      ...urgentPlants.map((plant) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildPlantCard(context, plant),
                      )),
                      
                      const SizedBox(height: 32),
                      
                      const Text('Próximas regas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CERESColors.textMain)),
                      const SizedBox(height: 16),

                      if (upcomingPlants.isEmpty)
                        const Text('Não tens regas agendadas.', style: TextStyle(color: CERESColors.textSecondary)),

                      // Despeja as plantas saudáveis/futuras
                      ...upcomingPlants.map((plant) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildPlantCard(context, plant),
                      )),
                      
                      const SizedBox(height: 80), // Margem de segurança para os cartões não se esconderem atrás da NavigationBar
                    ],
                  ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET AJUDANTE (CARTÃO DA PLANTA) ---
  Widget _buildPlantCard(BuildContext context, UserPlant plant) {
    // InkWell oferece um efeito "ripple" tátil que mostra ao utilizador que o cartão é clicável
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Envia o objeto inteiro via "extra" para a página de detalhes, poupando um novo pedido à base de dados!
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
            // Miniatura da foto da Planta
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
                  
                  // Texto Dinâmico que fica cor-de-laranja se a planta estiver urgente
                  Text(
                    plant.statusText, 
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 14, 
                      color: plant.isUrgent ? CERESColors.alertOrange : CERESColors.textMain, 
                    )
                  ),
                  const SizedBox(height: 4),
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
// Isolado do ecrã principal para garantir que os pedidos de GPS não atrasam o carregamento das Plantas
class WeatherBanner extends StatefulWidget {
  const WeatherBanner({super.key});

  @override
  State<WeatherBanner> createState() => _WeatherBannerState();
}

class _WeatherBannerState extends State<WeatherBanner> {
  final _weatherService = WeatherService();
  
  // Guardamos o Future numa variável late no estado para o pedido à API ser feito APENAS UMA VEZ
  late Future<String?> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _weatherService.getWeatherAlert();
  }

  // Função para dar uma segunda oportunidade quando o utilizador ativa as permissões
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Não mostra nada enquanto está a ligar a antena de GPS
        }

        final data = snapshot.data;

        // --- CENA DO GPS (TRATAMENTO DE EXCEÇÕES E UX) ---
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
                        // Mensagem adaptável consoante a recusa tenha sido de GPS ou da App
                        data == 'LOCATION_DISABLED' 
                          ? 'O GPS do telemóvel está desligado.' 
                          : 'Para receberes alertas meteorológicos, precisamos da tua localização.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Botão dinâmico de Call to Action
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Se ele bloqueou permanentemente na gaveta do Android, mandamos para as Definições do SO
                      if (data == 'DENIED_FOREVER') {
                        await Geolocator.openAppSettings();
                      } else if (data == 'LOCATION_DISABLED') {
                        await Geolocator.openLocationSettings();
                      } else {
                        // Tenta exibir o pop-up nativo de permissão mais uma vez
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

        // --- CENA DO TEMPO (SUCESSO: HÁ ALERTA) ---
        if (data != null && data.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
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
        
        // Se a API disse que está sol normal, o widget "implode" e fica invisível para não incomodar
        return const SizedBox.shrink();
      },
    );
  }
}