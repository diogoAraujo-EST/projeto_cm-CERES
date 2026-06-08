import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

// O serviço que liga o GPS à previsão do tempo
class WeatherService {
  
  // Função principal: Devolve uma String de texto se houver um alerta, 
  // ou "null" se o tempo estiver normal e não houver necessidade de avisar o utilizador.
  Future<String?> getWeatherAlert() async {
    try {
      // --- 1. A PARTE FÍSICA (HARDWARE) ---
      // Primeiro, verifica se a antena de GPS do telemóvel está ligada.
      // Não vale a pena pedir permissões à app se o telemóvel tem a "Localização" desligada lá em cima.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'LOCATION_DISABLED'; // A UI apanha isto e manda ligar o GPS
      }

      // --- 2. A PARTE DO SOFTWARE (PERMISSÕES) ---
      // Verifica se o utilizador deu autorização à nossa app (CERES) para usar o GPS
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Se ainda não deu, fazemos a pergunta (Aparece aquele pop-up do Android/iOS)
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'PERMISSION_DENIED'; // O utilizador clicou em "Não"
        }
      }
      
      // Se o utilizador já se chateou e clicou "Não voltar a perguntar",
      // o sistema operativo bloqueia-nos para sempre. Temos de o mandar para as Definições!
      if (permission == LocationPermission.deniedForever) {
        return 'DENIED_FOREVER';
      }

      // --- 3. APANHAR A LOCALIZAÇÃO ---
      // Como o Open-Meteo calcula o tempo por zonas grandes (cidades), 
      // LocationAccuracy.low é perfeito! Descobre onde estamos em 1 segundo e não drena a bateria do telemóvel.
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      
      // --- 4. A CHAMADA À API DE METEOROLOGIA ---
      // Passamos a nossa latitude e longitude para o Open-Meteo
      final String url = 'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Traduz o JSON bruto para um dicionário (Map) em Dart
        final data = json.decode(response.body);
        
        // A API usa a norma "WMO Weather Interpretation Codes"
        // Cada número significa um estado de tempo diferente (0 = Sol, 61 = Chuva, etc)
        final int weatherCode = data['current_weather']['weathercode'];
        final double temp = data['current_weather']['temperature'];

        // --- 5. O MOTOR DE REGRAS DOS ALERTAS ---
        
        // Se o código é 0 (Céu limpo) OU (está pouco nublado <=3 E a temperatura é alta > 25ºC)
        if (weatherCode == 0 || (weatherCode <= 3 && temp > 25)) {
          return ' Muito sol hoje ☀️($temp°C). Verifica a terra das tuas plantas!';
        } 
        // Se o código estiver na casa dos 50s ou 60s (Chuviscos e Chuva) ou 80s (Aguaceiros)
        else if ((weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)) {
          return 'Está a chover🌧️ ! Verifica as tuas plantas de exterior.';
        } 
        // Se o código for 71 ou superior (Neve, Granizo, Tempestades)
        else if (weatherCode >= 71) {
          return 'Tempo extremo lá fora❄️⛈️. Protege as plantas de exterior!';
        }
        
        // Se estiver "normal" (ex: Nublado com 18ºC), não chateamos a pessoa
        return null;
      }
      return null;
    } catch (e) {
      // Se a pessoa estiver sem internet, o http.get vai dar erro. 
      // Apanhamos o erro aqui silenciosamente e retornamos null para não crashar o ecrã Home.
      return null;
    }
  }
}