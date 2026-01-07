import 'dart:convert';
import 'dart:io';

import 'package:ai_backend/util/log_functions.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal() {
    // Load API Key
    final envFile = File('env/.env');
    final env = DotEnv(includePlatformEnvironment: true)..load([envFile.path]);
    _apiKey = env['GEMINI_API_KEY'] ?? '';

    if (_apiKey.isEmpty) {
      warningLog('WARNING: GEMINI_API_KEY not found in env/.env');
    }
  }
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent';
  late final String _apiKey;

  static final GeminiService _instance = GeminiService._internal();

  /// Generates embeddings using text-embedding-004 (768 dimensions)
  Future<List<double>> generateEmbedding(String text) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is missing.');
    }

    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey
        },
        body: jsonEncode(
          {
            'model': 'models/gemini-embedding-001',
            'content': {
              'parts': [
                {'text': text},
              ],
            },
            "output_dimensionality": 768,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final values = data['embedding']['values'] as List;
        return values.cast<double>();
      } else {
        throw Exception(
          'Failed to generate embedding: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      errorLog('Gemini Embedding Error: $e');
      rethrow;
    }
  }

  /// Chat completion using gemini-1.5-flash
  Future<String> chat(String userMessage, {String? systemPrompt}) async {
    if (_apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is missing.');
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent');

    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ]
      }
    ];

    final Map<String, dynamic> requestBody = {
      'contents': contents,
    };

    if (systemPrompt != null) {
      requestBody['systemInstruction'] = {
        'parts': [
          {'text': systemPrompt}
        ]
      };
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List;
          if (parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }
        throw Exception('No chat content returned');
      } else {
        throw Exception(
          'Failed to generate chat response: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      errorLog('Gemini Chat Error: $e');
      rethrow;
    }
  }
}
