import 'package:ai_backend/database/database_client.dart';
import 'dart:io';
import 'package:ai_backend/services/gemini_service.dart';
import 'package:ai_backend/services/mistral_service.dart';
import 'package:ai_backend/services/ollama_service.dart';
import 'package:dotenv/dotenv.dart';
import 'package:ai_backend/util/log_functions.dart';
import 'package:postgres/postgres.dart';

class RagManager {
  final DatabaseClient _dbClient = DatabaseClient();
  final MistralService _mistralService = MistralService();
  final OllamaService _ollamaService = OllamaService();
  final GeminiService _geminiService = GeminiService();
  late final String _provider;

  RagManager() {
    final envFile = File('env/.env');
    final env = DotEnv(includePlatformEnvironment: true)..load([envFile.path]);
    _provider = env['AI_PROVIDER']?.toUpperCase() ?? 'OLLAMA';
  }

  Future<String> askQuestion(String question) async {
    infoLog('RAG: Processing question: "$question"');

    // 1. Generate Embedding for the Question
    List<double> questionEmbedding;
    try {
      if (_provider == 'MISTRAL') {
        questionEmbedding = await _mistralService.generateEmbedding(question);
      } else if (_provider == 'GEMINI') {
        questionEmbedding = await _geminiService.generateEmbedding(question);
      } else {
        questionEmbedding = await _ollamaService.generateEmbedding(question);
      }
    } catch (e) {
      errorLog('Failed to generate embedding for question: $e');
      return 'Sorry, I faced an error understanding your question.';
    }

    // 2. Retrieve Relevant Context
    final context = await _retrieveContext(questionEmbedding);
    debugLog("Context: $context");
    if (context.isEmpty) {
      return 'I could not find any relevant information in the database to answer your question.';
    }

    infoLog('RAG: Retrieved ${context.length} relevant fragments.');

    // 3. Construct Prompt
    final prompt = _constructPrompt(question, context);

    // 4. Generate Answer via LLM
    try {
      const systemPrompt =
          'You are a helpful assistant for a school database. Answer the question based ONLY on the provided context. If the answer is not in the context, say so.';
      String answer;
      if (_provider == 'MISTRAL') {
        answer = await _mistralService.chat(prompt, systemPrompt: systemPrompt);
      } else if (_provider == 'GEMINI') {
        answer = await _geminiService.chat(prompt, systemPrompt: systemPrompt);
      } else {
        answer = await _ollamaService.chat(prompt, systemPrompt: systemPrompt);
      }
      return answer;
    } catch (e) {
      errorLog('Failed to generate answer from LLM: $e');
      return 'Sorry, I encountered an error while generating the answer.';
    }
  }

  Future<List<String>> _retrieveContext(List<double> embedding) async {
    final conn = await _dbClient.connection;
    final vectorString = '[${embedding.join(',')}]';

    // Search for top 10 most similar embeddings
    // We use cosine distance (<=>) for 768-dim (nomic) or others
    final result = await conn.execute(
      Sql.named('''
        SELECT content 
        FROM embeddings 
        ORDER BY embedding <=> @vector 
        
      '''),
      //LIMIT 20
      parameters: {'vector': vectorString},
    );

    return result.map((row) => row[0]! as String).toList();
  }

  String _constructPrompt(String question, List<String> context) {
    final buffer = StringBuffer();
    buffer.writeln('Context:');
    for (final item in context) {
      buffer.writeln('- $item');
    }
    buffer.writeln('\nQuestion: $question');
    buffer.writeln('Answer:');
    return buffer.toString();
  }
}
