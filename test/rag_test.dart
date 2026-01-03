import 'package:ai_backend/database/database_client.dart';
import 'package:ai_backend/managers/embedding_manager.dart';
import 'package:ai_backend/managers/rag_manager.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('RAG System Flow (Marks)', () async {
    final dbClient = DatabaseClient();
    await dbClient.ensureTablesExist();
    final conn = await dbClient.connection;

    // --- 1. Setup Data ---
    print('----------------------------------------------------------------');
    print('1. Setting up Test Data...');

    // Cleanup
    await conn.execute("DELETE FROM marks");
    await conn.execute("DELETE FROM students");
    await conn.execute("DELETE FROM subjects");
    await conn.execute("DELETE FROM embeddings");

    // Insert Subjects
    await conn.execute(
        "INSERT INTO subjects (id, name, code) VALUES (1, 'Mathematics', 'MATH101')");
    await conn.execute(
        "INSERT INTO subjects (id, name, code) VALUES (2, 'Physics', 'PHY101')");

    // Insert Students
    await conn.execute(
        "INSERT INTO students (id, name, age, grade, religion, sex) VALUES (1, 'Basheer', 15, '10-B', 'Islam', 'Male')");
    await conn.execute(
        "INSERT INTO students (id, name, age, grade, religion, sex) VALUES (2, 'Alice', 15, '10-A', 'Christian', 'Female')");

    // Insert Marks
    // Basheer: 90 in Math, 40 in Physics
    await conn.execute(
        "INSERT INTO marks (student_id, subject_id, score) VALUES (1, 1, 90)");
    await conn.execute(
        "INSERT INTO marks (student_id, subject_id, score) VALUES (1, 2, 40)");

    // Alice: 85 in Math, 95 in Physics
    await conn.execute(
        "INSERT INTO marks (student_id, subject_id, score) VALUES (2, 1, 85)");
    await conn.execute(
        "INSERT INTO marks (student_id, subject_id, score) VALUES (2, 2, 95)");

    // --- 2. Generate Embeddings ---
    print('2. Generating Embeddings...');
    final embeddingManager = EmbeddingManager();
    await embeddingManager.generateAndSaveEmbeddingsFor('marks');

    // --- 3. Ask Questions ---
    print('3. Asking Questions...');
    final ragManager = RagManager();

    // Q1: Specific Mark
    final answer1 = await ragManager
        .askQuestion("How much is the mark of Basheer in mathematics?");
    print('\nQ: How much is the mark of Basheer in mathematics?');
    print('A: $answer1\n');
    expect(answer1.contains('90'), true); // Expect 90 to be in the answer

    // Q2: Comparison
    final answer2 = await ragManager
        .askQuestion("Which students got more than 80 in Mathematics?");
    print('Q: Which students got more than 80 in Mathematics?');
    print('A: $answer2\n');
    expect(answer2.contains('Basheer'), true);
    expect(answer2.contains('Alice'), true);
  }, timeout: Timeout(Duration(minutes: 5)));
}
