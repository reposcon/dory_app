import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
  );

  static String? _cachedAdvice;

  /// Capa de Personalidad y Memoria
  static Future<String> getDorysAdvice({
    required double incomes,
    required double expenses,
    List<Map<String, dynamic>> recentMovements = const [],
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedAdvice != null && recentMovements.isEmpty) {
      return _cachedAdvice!;
    }
    
    final balance = incomes - expenses;
    
    // Prompt Base (Personalidad)
    String prompt = '''
Eres DORY, un pez con amnesia pero que curiosamente sabe finanzas. 
Tu usuario tiene un ingreso total de \$$incomes y un gasto total de \$$expenses. El balance actual es \$$balance.
Sé muy simpática, algo olvidadiza de forma graciosa y da un consejo amable. Puedes confundirte brevemente de vez en cuando pero siempre al final dales un buen consejo de ahorro.
''';

    if (recentMovements.isNotEmpty) {
      prompt += '\nEstos son sus últimos movimientos:\n';
      for (var mov in recentMovements) {
        prompt += '- ${mov['type']}: \$${mov['amount']} en ${mov['category']} (${mov['emoji']})\n';
      }
    }

    prompt += '\nGenera un mensaje corto (máximo 3 oraciones) para decirle al usuario en la pantalla principal de su app ("El Arrecife").';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text ?? 'Mmm... se me olvidó qué te iba a decir. ¡Ah, sí! Ahorra más.';
      if (recentMovements.isEmpty) {
        _cachedAdvice = text;
      }
      return text;
    } catch (e) {
      final str = e.toString().toLowerCase();
      if (str.contains('quota') || str.contains('exceeded') || str.contains('429')) {
        return '¡Uy! Parece que he conversado mucho hoy y me quedé sin burbujas. (Límite de uso gratuito de la API excedido). ¡Intenta más tarde o verifica tu plan de Google Gemini!';
      }
      return 'Ops, tragué agua y no pude procesar eso. ¡Qué olvidadiza soy! (Intenta de nuevo más tarde)';
    }
  }

  /// Capa Predictiva
  static Future<String> predictEndOfMonthBalance(List<Map<String, dynamic>> monthData) async {
    return "La niebla me dice que... llegarás a fin de mes, raspando.";
  }
}
