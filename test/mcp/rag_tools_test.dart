import 'package:test/test.dart';
import 'package:ai_backend/mcp/tools/rag_tools.dart';

void main() {
  group('RAG Tools', () {
    late RagTools ragTools;

    setUp(() {
      ragTools = RagTools();
    });

    test('getTools returns all RAG tools', () {
      final tools = ragTools.getTools();

      expect(tools.length, equals(3));
      expect(tools.any((t) => t.name == 'ask_question'), isTrue);
      expect(tools.any((t) => t.name == 'semantic_search'), isTrue);
      expect(tools.any((t) => t.name == 'query_students'), isTrue);
    });

    test('ask_question tool has correct schema', () {
      final tools = ragTools.getTools();
      final askQuestionTool = tools.firstWhere((t) => t.name == 'ask_question');

      expect(askQuestionTool.description, isNotEmpty);
      expect(askQuestionTool.inputSchema['type'], equals('object'));
      expect(askQuestionTool.inputSchema['properties'], isA<Map>());
      expect(askQuestionTool.inputSchema['required'], contains('question'));
    });

    test('semantic_search tool has correct schema', () {
      final tools = ragTools.getTools();
      final semanticSearchTool =
          tools.firstWhere((t) => t.name == 'semantic_search');

      expect(semanticSearchTool.description, isNotEmpty);
      expect(semanticSearchTool.inputSchema['type'], equals('object'));

      final properties = semanticSearchTool.inputSchema['properties'] as Map;
      expect(properties.containsKey('query'), isTrue);
      expect(properties.containsKey('limit'), isTrue);
      expect(semanticSearchTool.inputSchema['required'], contains('query'));
    });

    test('query_students tool has correct schema', () {
      final tools = ragTools.getTools();
      final queryStudentsTool =
          tools.firstWhere((t) => t.name == 'query_students');

      expect(queryStudentsTool.description, isNotEmpty);
      expect(queryStudentsTool.inputSchema['type'], equals('object'));

      final properties = queryStudentsTool.inputSchema['properties'] as Map;
      expect(properties.containsKey('name_filter'), isTrue);
      expect(properties.containsKey('division_id'), isTrue);
    });

    test('executeTool returns error for missing question parameter', () async {
      final result = await ragTools.executeTool('ask_question', {});

      expect(result.content, isNotEmpty);
      expect(result.content.first.type, equals('text'));

      final text = (result.content.first as dynamic).text as String;
      expect(text, contains('error'));
    });

    test('executeTool throws for unknown tool', () async {
      expect(
        () => ragTools.executeTool('unknown_tool', {}),
        throwsException,
      );
    });
  });
}
