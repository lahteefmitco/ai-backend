import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

class MistralService {
  final String _baseUrl = 'https://api.mistral.ai/v1/embeddings';
  final String _chatUrl = 'https://api.mistral.ai/v1/chat/completions';
  late final String _apiKey;

  factory MistralService() {
    return _instance;
  }

  MistralService._internal() {
    // Load API Key
    final envFile = File('env/.env');
    final env = DotEnv(includePlatformEnvironment: true)..load([envFile.path]);
    _apiKey = env['MISTRAL_API_KEY'] ?? '';

    if (_apiKey.isEmpty) {
      print('WARNING: MISTRAL_API_KEY not found in env/.env');
    }
  }

  static final MistralService _instance = MistralService._internal();

  /// Generates embeddings (1024 dimensions)
  Future<List<double>> generateEmbedding(String text) async {
    if (_apiKey.isEmpty) {
      throw Exception('MISTRAL_API_KEY is missing.');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'mistral-embed',
        'input': [text],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final embeddingData = data['data'] as List;
      if (embeddingData.isNotEmpty) {
        final embeddingList = embeddingData[0]['embedding'] as List;
        return embeddingList.cast<double>();
      } else {
        throw Exception('No embedding data returned');
      }
    } else {
      throw Exception(
        'Failed to generate embedding: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<String> chat(String userMessage, {String? systemPrompt}) async {
    if (_apiKey.isEmpty) {
      throw Exception('MISTRAL_API_KEY is missing.');
    }

    final messages = <Map<String, String>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': userMessage});

    final response = await http.post(
      Uri.parse(_chatUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'mistral-medium',
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        return choices[0]['message']['content'] as String;
      } else {
        throw Exception('No chat content returned');
      }
    } else {
      throw Exception(
        'Failed to generate chat response: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
