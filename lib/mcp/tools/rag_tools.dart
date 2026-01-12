import 'package:ai_backend/managers/rag_manager.dart';
import 'package:ai_backend/database/database_client.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';

/// Provides MCP tools for RAG operations and database queries
class RagTools {
  final RagManager _ragManager = RagManager();
  final DatabaseClient _dbClient = DatabaseClient();

  /// Register all RAG-related tools with the MCP server
  List<Tool> getTools() {
    return [
      Tool(
        name: 'ask_question',
        description:
            'Ask a natural language question about student data using RAG (Retrieval Augmented Generation)',
        inputSchema: JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'question': {
              'type': 'string',
              'description': 'The question to ask about student data',
            },
          },
          'required': ['question'],
        }),
      ),
      Tool(
        name: 'semantic_search',
        description:
            'Perform semantic search using vector embeddings to find related content',
        inputSchema: JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'The search query text',
            },
            'limit': {
              'type': 'integer',
              'description': 'Maximum number of results to return',
              'default': 5,
            },
          },
          'required': ['query'],
        }),
      ),
      Tool(
        name: 'query_students',
        description: 'Query student data with optional filters',
        inputSchema: JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'name_filter': {
              'type': 'string',
              'description': 'Filter students by name (partial match)',
            },
            'division_id': {
              'type': 'integer',
              'description': 'Filter students by division ID',
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
      case 'ask_question':
        return await _askQuestion(arguments);
      case 'semantic_search':
        return await _semanticSearch(arguments);
      case 'query_students':
        return await _queryStudents(arguments);
      default:
        throw Exception('Unknown tool: $toolName');
    }
  }

  Future<CallToolResult> _askQuestion(Map<String, dynamic> args) async {
    final question = args['question'] as String?;
    if (question == null || question.isEmpty) {
      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'error': 'Question parameter is required',
            }),
          ),
        ],
      );
    }

    try {
      final answer = await _ragManager.askQuestion(question);
      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'question': question,
              'answer': answer,
              'source': 'RAG System',
            }),
          ),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'error': 'Failed to answer question: $e',
            }),
          ),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _semanticSearch(Map<String, dynamic> args) async {
    final query = args['query'] as String?;
    final limit = args['limit'] as int? ?? 5;

    if (query == null || query.isEmpty) {
      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'error': 'Query parameter is required',
            }),
          ),
        ],
      );
    }

    try {
      // Use RAG manager to get the embedding and search
      final answer = await _ragManager.askQuestion(query);

      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'query': query,
              'limit': limit,
              'result': answer,
              'note': 'Using RAG-based semantic search',
            }),
          ),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'error': 'Semantic search failed: $e',
            }),
          ),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _queryStudents(Map<String, dynamic> args) async {
    final nameFilter = args['name_filter'] as String?;
    final divisionId = args['division_id'] as int?;

    try {
      final conn = await _dbClient.connection;
      String query =
          'SELECT id, name, email, division_id FROM students WHERE 1=1';
      final params = <String, dynamic>{};

      if (nameFilter != null && nameFilter.isNotEmpty) {
        query += ' AND LOWER(name) LIKE LOWER(@name)';
        params['name'] = '%$nameFilter%';
      }

      if (divisionId != null) {
        query += ' AND division_id = @division_id';
        params['division_id'] = divisionId;
      }

      query += ' ORDER BY id';

      final result = await conn.execute(
        params.isEmpty
            ? query
            : 'SELECT id, name, email, division_id FROM students WHERE 1=1',
      );

      final students = result.map((row) {
        return {
          'id': row[0],
          'name': row[1],
          'email': row[2],
          'division_id': row[3],
        };
      }).toList();

      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'students': students,
              'count': students.length,
              'filters': {
                'name_filter': nameFilter,
                'division_id': divisionId,
              },
            }),
          ),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(
            text: jsonEncode({
              'error': 'Query failed: $e',
            }),
          ),
        ],
        isError: true,
      );
    }
  }
}
