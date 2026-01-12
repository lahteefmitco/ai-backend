import 'package:test/test.dart';
import 'package:ai_backend/mcp/resources/database_resources.dart';

void main() {
  group('Database Resources', () {
    late DatabaseResources dbResources;

    setUp(() {
      dbResources = DatabaseResources();
    });

    test('getResources returns all database resources', () async {
      final resources = await dbResources.getResources();

      expect(resources.length, equals(5));
      expect(resources.any((r) => r.uri == 'database://students'), isTrue);
      expect(resources.any((r) => r.uri == 'database://subjects'), isTrue);
      expect(resources.any((r) => r.uri == 'database://marks'), isTrue);
      expect(resources.any((r) => r.uri == 'database://embeddings'), isTrue);
      expect(resources.any((r) => r.uri == 'database://divisions'), isTrue);
    });

    test('all resources have correct mime type', () async {
      final resources = await dbResources.getResources();

      for (final resource in resources) {
        expect(resource.mimeType, equals('application/json'));
      }
    });

    test('all resources have name and description', () async {
      final resources = await dbResources.getResources();

      for (final resource in resources) {
        expect(resource.name, isNotEmpty);
        expect(resource.description, isNotEmpty);
      }
    });

    test('readResource throws for unknown URI', () async {
      expect(
        () => dbResources.readResource('database://unknown'),
        throwsException,
      );
    });

    test('students resource has correct structure', () async {
      final resources = await dbResources.getResources();
      final studentsResource =
          resources.firstWhere((r) => r.uri == 'database://students');

      expect(studentsResource.name, equals('Students Database'));
      expect(studentsResource.uri, equals('database://students'));
    });

    test('marks resource has correct structure', () async {
      final resources = await dbResources.getResources();
      final marksResource =
          resources.firstWhere((r) => r.uri == 'database://marks');

      expect(marksResource.name, equals('Marks Database'));
      expect(marksResource.uri, equals('database://marks'));
      expect(marksResource.description, contains('contextual'));
    });
  });
}
