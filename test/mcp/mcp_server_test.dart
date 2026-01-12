import 'package:test/test.dart';
import 'package:ai_backend/mcp/mcp_server.dart';

void main() {
  group('MCP Server', () {
    late McpServerImpl server;

    setUp(() {
      server = McpServerImpl();
    });

    test('getServerInfo returns correct structure', () {
      final info = server.getServerInfo();

      expect(info['name'], equals('AI Backend MCP Server'));
      expect(info['version'], equals('1.0.0'));
      expect(info['protocol_version'], equals('2025-11-25'));
      expect(info['capabilities'], isA<Map>());
      expect(info['capabilities']['resources'], isTrue);
      expect(info['capabilities']['tools'], isTrue);
    });

    test('getResourcesList returns resources', () async {
      final resourcesList = await server.getResourcesList();

      expect(resourcesList['resources'], isA<List>());
      expect(resourcesList['count'], greaterThan(0));

      final resources = resourcesList['resources'] as List;
      expect(resources.any((r) => r['uri'] == 'database://students'), isTrue);
      expect(resources.any((r) => r['uri'] == 'database://subjects'), isTrue);
      expect(resources.any((r) => r['uri'] == 'database://marks'), isTrue);
      expect(resources.any((r) => r['uri'] == 'database://embeddings'), isTrue);
    });

    test('getToolsList returns tools', () {
      final toolsList = server.getToolsList();

      expect(toolsList['tools'], isA<List>());
      expect(toolsList['count'], greaterThan(0));

      final tools = toolsList['tools'] as List;

      // Check for RAG tools
      expect(tools.any((t) => t['name'] == 'ask_question'), isTrue);
      expect(tools.any((t) => t['name'] == 'semantic_search'), isTrue);

      // Check for database tools
      expect(tools.any((t) => t['name'] == 'get_student_info'), isTrue);
      expect(tools.any((t) => t['name'] == 'get_student_marks'), isTrue);
      expect(tools.any((t) => t['name'] == 'search_students'), isTrue);
    });

    test('all tools have required fields', () {
      final toolsList = server.getToolsList();
      final tools = toolsList['tools'] as List;

      for (final tool in tools) {
        expect(tool['name'], isA<String>());
        expect(tool['description'], isA<String>());
        expect(tool['inputSchema'], isA<Map>());

        final schema = tool['inputSchema'] as Map;
        expect(schema['type'], equals('object'));
        expect(schema['properties'], isA<Map>());
      }
    });

    test('all resources have required fields', () async {
      final resourcesList = await server.getResourcesList();
      final resources = resourcesList['resources'] as List;

      for (final resource in resources) {
        expect(resource['uri'], isA<String>());
        expect(resource['name'], isA<String>());
        expect(resource['description'], isA<String>());
        expect(resource['mimeType'], equals('application/json'));
      }
    });
  });
}
