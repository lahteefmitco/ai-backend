import 'package:ai_backend/database/database_client.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';

/// Provides MCP resources for accessing database entities
class DatabaseResources {
  final DatabaseClient _dbClient = DatabaseClient();

  /// Register all database resources with the MCP server
  Future<List<Resource>> getResources() async {
    return [
      Resource(
        uri: 'database://students',
        name: 'Students Database',
        description: 'List of all students in the database',
        mimeType: 'application/json',
      ),
      Resource(
        uri: 'database://subjects',
        name: 'Subjects Database',
        description: 'List of all subjects in the database',
        mimeType: 'application/json',
      ),
      Resource(
        uri: 'database://marks',
        name: 'Marks Database',
        description: 'Student marks with contextual information',
        mimeType: 'application/json',
      ),
      Resource(
        uri: 'database://embeddings',
        name: 'Embeddings Database',
        description: 'Vector embeddings for semantic search',
        mimeType: 'application/json',
      ),
      Resource(
        uri: 'database://divisions',
        name: 'Divisions Database',
        description: 'List of all divisions',
        mimeType: 'application/json',
      ),
    ];
  }

  /// Read a specific resource by URI
  Future<TextResourceContents> readResource(String uri) async {
    final conn = await _dbClient.connection;

    switch (uri) {
      case 'database://students':
        final result = await conn.execute(
          'SELECT id, name, email, division_id, created_at FROM students ORDER BY id',
        );
        final students = result.map((row) {
          return {
            'id': row[0],
            'name': row[1],
            'email': row[2],
            'division_id': row[3],
            'created_at': row[4].toString(),
          };
        }).toList();

        return TextResourceContents(
          uri: uri,
          mimeType: 'application/json',
          text: jsonEncode({'students': students, 'count': students.length}),
        );

      case 'database://subjects':
        final result = await conn.execute(
          'SELECT id, name, code, created_at FROM subjects ORDER BY id',
        );
        final subjects = result.map((row) {
          return {
            'id': row[0],
            'name': row[1],
            'code': row[2],
            'created_at': row[3].toString(),
          };
        }).toList();

        return TextResourceContents(
          uri: uri,
          mimeType: 'application/json',
          text: jsonEncode({'subjects': subjects, 'count': subjects.length}),
        );

      case 'database://marks':
        final result = await conn.execute('''
          SELECT 
            m.id,
            s.name as student_name,
            sub.name as subject_name,
            m.mark,
            m.max_mark,
            m.created_at
          FROM marks m
          JOIN students s ON m.student_id = s.id
          JOIN subjects sub ON m.subject_id = sub.id
          ORDER BY m.id
        ''');
        final marks = result.map((row) {
          return {
            'id': row[0],
            'student_name': row[1],
            'subject_name': row[2],
            'mark': row[3],
            'max_mark': row[4],
            'created_at': row[5].toString(),
          };
        }).toList();

        return TextResourceContents(
          uri: uri,
          mimeType: 'application/json',
          text: jsonEncode({'marks': marks, 'count': marks.length}),
        );

      case 'database://embeddings':
        final result = await conn.execute(
          'SELECT id, content, created_at FROM embeddings ORDER BY id LIMIT 100',
        );
        final embeddings = result.map((row) {
          return {
            'id': row[0],
            'content': row[1],
            'created_at': row[2].toString(),
          };
        }).toList();

        return TextResourceContents(
          uri: uri,
          mimeType: 'application/json',
          text: jsonEncode({
            'embeddings': embeddings,
            'count': embeddings.length,
            'note': 'Limited to first 100 embeddings',
          }),
        );

      case 'database://divisions':
        final result = await conn.execute(
          'SELECT id, name, year, created_at FROM divisions ORDER BY id',
        );
        final divisions = result.map((row) {
          return {
            'id': row[0],
            'name': row[1],
            'year': row[2],
            'created_at': row[3].toString(),
          };
        }).toList();

        return TextResourceContents(
          uri: uri,
          mimeType: 'application/json',
          text: jsonEncode({'divisions': divisions, 'count': divisions.length}),
        );

      default:
        throw Exception('Unknown resource URI: $uri');
    }
  }
}
