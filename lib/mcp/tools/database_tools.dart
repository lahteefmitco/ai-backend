import 'package:ai_backend/database/database_client.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';

/// Provides MCP tools for direct database operations
class DatabaseTools {
  final DatabaseClient _dbClient = DatabaseClient();

  /// Register all database tools with the MCP server
  List<Tool> getTools() {
    return [
      Tool(
        name: 'get_student_info',
        description: 'Retrieve detailed information about a specific student',
        inputSchema: JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'student_id': {
              'type': 'integer',
              'description': 'The ID of the student',
            },
          },
          'required': ['student_id'],
        }),
      ),
      Tool(
        name: 'get_student_marks',
        description: 'Get all marks for a specific student',
        inputSchema: JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'student_id': {
              'type': 'integer',
              'description': 'The ID of the student',
            },
          },
          'required': ['student_id'],
        }),
      ),
      Tool(
        name: 'search_students',
        description: 'Search for students by name or division',
        inputSchema: JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'search_term': {
              'type': 'string',
              'description': 'Name or partial name to search for',
            },
            'division': {
              'type': 'string',
              'description': 'Division name to filter by',
            },
          },
        }),
      ),
    ];
  }

  /// Execute a tool by name with given arguments
  Future<CallToolResult> executeTool(
      String toolName, Map<String, dynamic> arguments) async {
    switch (toolName) {
      case 'get_student_info':
        return await _getStudentInfo(arguments);
      case 'get_student_marks':
        return await _getStudentMarks(arguments);
      case 'search_students':
        return await _searchStudents(arguments);
      default:
        throw Exception('Unknown tool: $toolName');
    }
  }

  Future<CallToolResult> _getStudentInfo(Map<String, dynamic> args) async {
    final studentId = args['student_id'] as int?;
    if (studentId == null) {
      return CallToolResult(
        content: [
          TextContent(text: jsonEncode({'error': 'student_id is required'})),
        ],
      );
    }

    try {
      final conn = await _dbClient.connection;
      final result = await conn.execute(
        '''
        SELECT s.id, s.name, s.email, d.name as division_name, s.created_at
        FROM students s
        LEFT JOIN divisions d ON s.division_id = d.id
        WHERE s.id = @id
        ''',
        parameters: {'id': studentId},
      );

      if (result.isEmpty) {
        return CallToolResult(
          content: [
            TextContent(text: jsonEncode({'error': 'Student not found'})),
          ],
        );
      }

      final student = result.first;
      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'student': {
                'id': student[0],
                'name': student[1],
                'email': student[2],
                'division': student[3],
                'created_at': student[4].toString(),
              },
            }),
          ),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(
              text: jsonEncode({'error': 'Failed to get student info: $e'})),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _getStudentMarks(Map<String, dynamic> args) async {
    final studentId = args['student_id'] as int?;
    if (studentId == null) {
      return CallToolResult(
        content: [
          TextContent(text: jsonEncode({'error': 'student_id is required'})),
        ],
      );
    }

    try {
      final conn = await _dbClient.connection;
      final result = await conn.execute(
        '''
        SELECT 
          m.id,
          sub.name as subject_name,
          sub.code as subject_code,
          m.mark,
          m.max_mark,
          m.created_at
        FROM marks m
        JOIN subjects sub ON m.subject_id = sub.id
        WHERE m.student_id = @student_id
        ORDER BY sub.name
        ''',
        parameters: {'student_id': studentId},
      );

      final marks = result.map((row) {
        return {
          'id': row[0],
          'subject_name': row[1],
          'subject_code': row[2],
          'mark': row[3],
          'max_mark': row[4],
          'percentage':
              ((row[3] as num) / (row[4] as num) * 100).toStringAsFixed(2),
          'created_at': row[5].toString(),
        };
      }).toList();

      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'student_id': studentId,
              'marks': marks,
              'count': marks.length,
            }),
          ),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(
              text: jsonEncode({'error': 'Failed to get student marks: $e'})),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _searchStudents(Map<String, dynamic> args) async {
    final searchTerm = args['search_term'] as String?;
    final division = args['division'] as String?;

    try {
      final conn = await _dbClient.connection;
      String query = '''
        SELECT s.id, s.name, s.email, d.name as division_name
        FROM students s
        LEFT JOIN divisions d ON s.division_id = d.id
        WHERE 1=1
      ''';

      if (searchTerm != null && searchTerm.isNotEmpty) {
        query += " AND LOWER(s.name) LIKE '%${searchTerm.toLowerCase()}%'";
      }

      if (division != null && division.isNotEmpty) {
        query += " AND LOWER(d.name) LIKE '%${division.toLowerCase()}%'";
      }

      query += ' ORDER BY s.name';

      final result = await conn.execute(query);

      final students = result.map((row) {
        return {
          'id': row[0],
          'name': row[1],
          'email': row[2],
          'division': row[3],
        };
      }).toList();

      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'students': students,
              'count': students.length,
              'search_term': searchTerm,
              'division': division,
            }),
          ),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: jsonEncode({'error': 'Search failed: $e'})),
        ],
        isError: true,
      );
    }
  }
}
