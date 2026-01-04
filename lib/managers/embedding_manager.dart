import 'dart:io';

import 'package:ai_backend/database/database_client.dart';
import 'package:ai_backend/services/mistral_service.dart';
import 'package:ai_backend/services/ollama_service.dart';
import 'package:ai_backend/util/log_functions.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

class EmbeddingManager {

  EmbeddingManager() {
    final envFile = File('env/.env');
    final env = DotEnv(includePlatformEnvironment: true)..load([envFile.path]);
    _provider = env['AI_PROVIDER']?.toUpperCase() ?? 'OLLAMA';
  }
  final DatabaseClient _dbClient = DatabaseClient();
  final MistralService _mistralService = MistralService();
  final OllamaService _ollamaService = OllamaService();
  late final String _provider;

  
  Future<void> generateAndSaveEmbeddingsFor(String tableName) async {
    final conn = await _dbClient.connection;
    infoLog('Generating embeddings for table: $tableName');

    // Fetch all records from the table
    // Note: This is a simplified approach. In a real app, you might want to process in batches
    // and only process records that don't have embeddings yet.
    try {
      if (tableName == 'marks') {
        await _generateMarksEmbeddings(conn);
        return;
      }

      final result = await conn.execute('SELECT * FROM $tableName');

      for (final row in result) {
        final recordMap = row.toColumnMap();
        final id = recordMap['id'] as int;

        // Convert record to text based on table name
        String? contentText;
        Map<String, dynamic>? metadata;

        switch (tableName) {
          case 'students':
            contentText = _studentToText(recordMap);
            metadata = _getStudentMetadata(recordMap);
            break;
          case 'subjects':
            contentText = _subjectToText(recordMap);
            metadata = _getSubjectMetadata(recordMap);
            break;
          // Add other cases as needed
          default:
            warningLog('Skipping unknown table: $tableName');
            continue;
        }

        if (contentText.isNotEmpty) {
          try {
            // Generate Embedding
            List<double> embedding;
            if (_provider == 'MISTRAL') {
              embedding = await _mistralService.generateEmbedding(contentText);
            } else {
              embedding = await _ollamaService.generateEmbedding(contentText);
            }

            // Save to database
            await _saveEmbedding(
                conn, tableName, id, embedding, contentText, metadata);
            greenLog('Saved embedding for $tableName record ID: $id');
            // Avoid Rate Limit
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            errorLog(
                'Error generating/saving embedding for $tableName ID $id: $e');
          }
        }
      }
    } catch (e) {
      errorLog('Error processing table $tableName: $e');
    }
  }

  Future<void> _generateMarksEmbeddings(Connection conn) async {
    infoLog('Generating embeddings for Marks with JOINs...');
    final result = await conn.execute('''
      SELECT 
        m.id, m.score, 
        s.name as student_name, s.grade, s.sex, 
        sub.name as subject_name 
      FROM marks m 
      JOIN students s ON m.student_id = s.id 
      JOIN subjects sub ON m.subject_id = sub.id
    ''');

    for (final row in result) {
      final data = row.toColumnMap();
      final id = data['id'] as int;

      final studentName = data['student_name'];
      final subjectName = data['subject_name'];
      final score = data['score'];
      final grade = data['grade'];
      final sex = data['sex'];

      final contentText =
          'Student $studentName (Grade $grade, Sex $sex) scored $score in $subjectName.';

      final metadata = {
        'type': 'mark',
        'student_name': studentName,
        'subject': subjectName,
        'score': score,
        'grade': grade,
        'sex': sex,
      };

      try {
        List<double> embedding;
        if (_provider == 'MISTRAL') {
          embedding = await _mistralService.generateEmbedding(contentText);
        } else {
          embedding = await _ollamaService.generateEmbedding(contentText);
        }
        await _saveEmbedding(
            conn, 'marks', id, embedding, contentText, metadata);
        greenLog(
            'Saved embedding for Mark ID: $id ($studentName - $subjectName)');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        errorLog('Error saving mark embedding $id: $e');
      }
    }
  }

  String _studentToText(Map<String, dynamic> data) {
    return 'Student Name: ${data['name']}, Age: ${data['age']}, Grade: ${data['grade']}, Religion: ${data['religion'] ?? 'N/A'}, Address: ${data['address'] ?? 'N/A'}, Sex: ${data['sex'] ?? 'N/A'}';
  }

  String _subjectToText(Map<String, dynamic> data) {
    return 'Subject: ${data['name']}, Code: ${data['code']}';
  }

  Map<String, dynamic> _getStudentMetadata(Map<String, dynamic> data) {
    return {
      'grade': data['grade'],
      'religion': data['religion'],
      'sex': data['sex'],
    };
  }

  Map<String, dynamic> _getSubjectMetadata(Map<String, dynamic> data) {
    return {
      'code': data['code'],
    };
  }

  Future<void> _saveEmbedding(
      Connection conn,
      String tableName,
      int recordId,
      List<double> embedding,
      String content,
      Map<String, dynamic>? metadata) async {
    // Format vector for pgvector
    final vectorString = '[${embedding.join(',')}]';
    // Encode metadata to JSON
    // final metadataJson = metadata != null ? jsonEncode(metadata) : null;

    await conn.execute(
        Sql.named(
            'INSERT INTO embeddings (table_name, record_id, embedding, content, metadata) VALUES (@tableName, @recordId, @embedding, @content, @metadata)'),
        parameters: {
          'tableName': tableName,
          'recordId': recordId,
          'embedding': vectorString,
          'content': content,
          'metadata': metadata,
        });
  }
}
