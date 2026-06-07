import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // --- O TRUQUE DO SINGLETON ---
  // Estas 3 linhas garantem que a app só cria UM único "Carteiro" (instância) na memória.
  // Se tivéssemos vários, eles podiam atropelar-se e enviar a mesma notificação duas vezes!
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // A ferramenta principal do pacote que instalaste
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // --- PREPARAÇÃO INICIAL (Obrigatório correr no main.dart) ---
  Future<void> init() async {
    // 1. Dizemos ao Android onde está o ícone que vai aparecer lá em cima pequenino na barra
    // (O '@mipmap/ic_launcher' vai buscar o logo oficial da app)
    const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // 2. O iOS é esquisito e precisa que a gente declare logo à partida que queremos 
    // enviar alertas (popups), badges (a bolinha vermelha com números no ícone da app) e tocar sons.
    const DarwinInitializationSettings initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 3. Juntamos as duas preparações num pacote só
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    // CORREÇÃO 1: Adicionado o nome do parâmetro "initializationSettings:"
    // (Avisa o sistema operativo do telemóvel que estamos prontos para trabalhar)
    await _notificationsPlugin.initialize(
      settings: initSettings,
    );
  }

  // --- PEDIR AUTORIZAÇÃO ---
  // A partir do Android 13, já não podes enviar notificações sem pedir autorização primeiro!
  // É esta função que faz aparecer aquele pop-up do sistema a dizer: "A app quer enviar-te notificações".
  Future<void> requestPermissions() async {
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  // --- ENVIAR NOTIFICAÇÃO IMEDIATA ---
  Future<void> showInstantNotification({int id = 0, required String title, required String body}) async {
    
    // O Android usa um sistema de "Canais" (Channels). 
    // Imagina a TV: Tens o canal de Notícias, o canal de Desporto, etc.
    // Aqui criámos o canal 'ceres_rega_channel'. Se o utilizador for às definições do telemóvel, 
    // ele pode desligar este canal específico mas manter outros ligados!
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ceres_rega_channel', // O ID técnico do canal
      'Lembretes de Rega',  // O nome bonito que o utilizador lê nas definições do telemóvel
      channelDescription: 'Notificações para regar as plantas',
      importance: Importance.max, // Importância MAX faz a notificação saltar logo no ecrã (Heads-up)
      priority: Priority.high,    // Prioridade alta diz ao telemóvel para não adiar a entrega
      icon: '@mipmap/ic_launcher',
    );

    // Embrulha as definições para Android e iOS (O iOS chama-se Darwin por causa do motor da Apple)
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // CORREÇÃO 2: Todos os parâmetros agora têm de ser explicitamente nomeados
    // Faz o "push" final! O telemóvel vibra e o alerta aparece!
    await _notificationsPlugin.show(
      id: id,         // Se enviares 2 notificações com o mesmo ID, a segunda apaga/substitui a primeira!
      title: title,   // Título em bold
      body: body,     // O texto descritivo por baixo
      notificationDetails: platformDetails,
    );
  }
}