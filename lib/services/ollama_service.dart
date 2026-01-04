import 'dart:convert';

import 'package:ai_backend/util/log_functions.dart';
import 'package:http/http.dart' as http;

class OllamaService {

  factory OllamaService() {
    return _instance;
  }

  OllamaService._internal();
  final String _baseUrl = 'http://localhost:11434/api';

  // Singleton instance
  static final OllamaService _instance = OllamaService._internal();

  /// Generates text embeddings using nomic-embed-text (768 dimensions)
  Future<List<double>> generateEmbedding(String text) async {
    final url = Uri.parse('$_baseUrl/embeddings');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'nomic-embed-text',
          'prompt': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = List<double>.from(data['embedding'] as List);
        return embedding;
      } else {
        throw Exception(
            'Failed to generate embedding: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      errorLog('Ollama Embedding Error: $e');
      rethrow;
    }
  }

  /// Chat completion using llama3
  Future<String> chat(String userMessage, {String? systemPrompt}) async {
    final url = Uri.parse('$_baseUrl/chat');

    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': userMessage});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama3',
          'messages': messages,
          'stream': false, // Turn off streaming for simpler handling
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']['content'] as String;
      } else {
        throw Exception(
            'Failed to generate chat response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      errorLog('Ollama Chat Error: $e');
      rethrow;
    }
  }
}
