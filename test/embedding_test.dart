import 'package:ai_backend/database/database_client.dart';
import 'package:ai_backend/managers/embedding_manager.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('Embedding Generation Flow', () async {
    final dbClient = DatabaseClient();
    await dbClient.ensureTablesExist();
    final conn = await dbClient.connection;

    // 1. Insert a dummy student
    await conn
        .execute("DELETE FROM students WHERE name = 'Test Student'"); // Cleanup

    await conn.execute(
        Sql.named(
            "INSERT INTO students (name, age, grade, religion, address, sex) VALUES (@name, @age, @grade, @religion, @address, @sex)"),
        parameters: {
          'name': 'Test Student',
          'age': 20,
          'grade': 'A',
          'religion': 'None',
          'address': '123 Test St',
          'sex': 'Male'
        });

    // 2. Run Embedding Manager
    final manager = EmbeddingManager();
    await manager.generateAndSaveEmbeddingsFor('students');

    // 3. Verify Embedding Exists
    final result = await conn.execute(
        "SELECT * FROM embeddings WHERE content LIKE '%Test Student%'");

    expect(result.isNotEmpty, true);
    final row = result.first.toColumnMap();
    expect(row['table_name'], 'students');
    expect(row['embedding'], isNotNull);

    // Check Metadata
    expect(row['metadata'], isNotNull);
    final metadata = row['metadata'];
    if (metadata is Map) {
      expect(metadata['grade'], 'A');
      expect(metadata['sex'], 'Male');
    }

    print('Verification Successful: Embedding found for Test Student.');

    // Cleanup
    await conn.execute("DELETE FROM students WHERE name = 'Test Student'");
    await conn
        .execute("DELETE FROM embeddings WHERE content LIKE '%Test Student%'");
  }, timeout: Timeout(Duration(minutes: 2)));
}
