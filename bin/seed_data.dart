import 'dart:io';
import 'dart:math';

import 'package:ai_backend/database/database_client.dart';
import 'package:ai_backend/managers/embedding_manager.dart';
import 'package:ai_backend/util/log_functions.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

void main() async {
  final dbClient = DatabaseClient();
  await dbClient.ensureTablesExist();
  final conn = await dbClient.connection;

  infoLog('Starting database seeding...');

  // --- Clear Tables ---
  await conn.execute(
      'TRUNCATE TABLE marks, fees, students, subjects, divisions, users, embeddings RESTART IDENTITY CASCADE');
  infoLog('Tables cleared.');

  // --- Seed Divisions ---
  final divisions = [
    '10-A',
    '10-B',
    '10-C',
    '11-A',
    '11-B',
    '12-A',
    '12-B',
    '9-A',
    '9-B',
    '8-A'
  ];
  for (final div in divisions) {
    await conn.execute(Sql.named('INSERT INTO divisions (name) VALUES (@name)'),
        parameters: {'name': div});
  }
  greenLog('Seeded ${divisions.length} Divisions.');

  // --- Seed Subjects ---
  final subjects = [
    {'name': 'Mathematics', 'code': 'MATH101'},
    {'name': 'Physics', 'code': 'PHY101'},
    {'name': 'Chemistry', 'code': 'CHEM101'},
    {'name': 'Biology', 'code': 'BIO101'},
    {'name': 'English', 'code': 'ENG101'},
    {'name': 'History', 'code': 'HIST101'},
    {'name': 'Geography', 'code': 'GEO101'},
    {'name': 'Computer Science', 'code': 'CS101'},
    {'name': 'Economics', 'code': 'ECO101'},
    {'name': 'Art', 'code': 'ART101'},
  ];
  for (final sub in subjects) {
    await conn.execute(
        Sql.named('INSERT INTO subjects (name, code) VALUES (@name, @code)'),
        parameters: {'name': sub['name'], 'code': sub['code']});
  }
  greenLog('Seeded ${subjects.length} Subjects.');

  // --- Seed Students ---
  final students = [
    {
      'name': 'Basheer',
      'age': 15,
      'grade': '10-A',
      'religion': 'Islam',
      'sex': 'Male'
    },
    {
      'name': 'Alice',
      'age': 15,
      'grade': '10-B',
      'religion': 'Christian',
      'sex': 'Female'
    },
    {
      'name': 'Rahul',
      'age': 16,
      'grade': '11-A',
      'religion': 'Hindu',
      'sex': 'Male'
    },
    {
      'name': 'Fatima',
      'age': 14,
      'grade': '9-A',
      'religion': 'Islam',
      'sex': 'Female'
    },
    {
      'name': 'John',
      'age': 17,
      'grade': '12-A',
      'religion': 'Christian',
      'sex': 'Male'
    },
    {
      'name': 'Priya',
      'age': 15,
      'grade': '10-A',
      'religion': 'Hindu',
      'sex': 'Female'
    },
    {
      'name': 'Ahmed',
      'age': 16,
      'grade': '11-B',
      'religion': 'Islam',
      'sex': 'Male'
    },
    {
      'name': 'Sarah',
      'age': 14,
      'grade': '9-B',
      'religion': 'Christian',
      'sex': 'Female'
    },
    {
      'name': 'Arjun',
      'age': 17,
      'grade': '12-B',
      'religion': 'Hindu',
      'sex': 'Male'
    },
    {
      'name': 'Zainab',
      'age': 13,
      'grade': '8-A',
      'religion': 'Islam',
      'sex': 'Female'
    },
    {
      'name': 'David',
      'age': 15,
      'grade': '10-C',
      'religion': 'Christian',
      'sex': 'Male'
    },
    {
      'name': 'Sneha',
      'age': 16,
      'grade': '11-A',
      'religion': 'Hindu',
      'sex': 'Female'
    },
  ];

  for (final st in students) {
    await conn.execute(
        Sql.named(
            'INSERT INTO students (name, age, grade, religion, address, sex) VALUES (@name, @age, @grade, @religion, @address, @sex)'),
        parameters: {
          'name': st['name'],
          'age': st['age'],
          'grade': st['grade'],
          'religion': st['religion'],
          'address': 'Some Address', // Simplified
          'sex': st['sex']
        });
  }
  greenLog('Seeded ${students.length} Students.');

  // --- Seed Users ---
  for (var i = 1; i <= 10; i++) {
    final hashedPassword = BCrypt.hashpw('password123', BCrypt.gensalt());
    await conn.execute(
        Sql.named(
            'INSERT INTO users (username, password) VALUES (@username, @password)'),
        parameters: {'username': 'user$i', 'password': hashedPassword});
  }
  greenLog('Seeded 10 Users.');

  // --- Seed Marks ---
  final random = Random();
  final studentResult = await conn.execute('SELECT id FROM students');
  final subjectResult = await conn.execute('SELECT id FROM subjects');
  final studentIds = studentResult.map((r) => r[0] as int).toList();
  final subjectIds = subjectResult.map((r) => r[0] as int).toList();

  int markCount = 0;
  for (final sID in studentIds) {
    // Assign marks for random 5 subjects for each student
    final shuffledSubjects = List.of(subjectIds)..shuffle();
    final selectedSubjects = shuffledSubjects.take(5);

    for (final subID in selectedSubjects) {
      final score = 30 + random.nextInt(71); // Score between 30 and 100
      await conn.execute(
          Sql.named(
              'INSERT INTO marks (student_id, subject_id, score) VALUES (@sid, @subid, @score)'),
          parameters: {'sid': sID, 'subid': subID, 'score': score});
      markCount++;
    }
  }
  greenLog('Seeded $markCount Marks.');

  // --- Seed Fees ---
  int feeCount = 0;
  for (final sID in studentIds) {
    final amount = (random.nextInt(5) + 1) * 1000;
    final status = random.nextBool() ? 'PAID' : 'PENDING';
    await conn.execute(
        Sql.named(
            'INSERT INTO fees (student_id, amount, status) VALUES (@sid, @amount, @status)'),
        parameters: {'sid': sID, 'amount': amount, 'status': status});
    feeCount++;
  }
  greenLog('Seeded $feeCount Fees.');

  // --- Generate Embeddings ---
  infoLog('Generating Embeddings...');
  final embeddingManager = EmbeddingManager();

  await embeddingManager.generateAndSaveEmbeddingsFor('students');
  await embeddingManager.generateAndSaveEmbeddingsFor('subjects');
  await embeddingManager.generateAndSaveEmbeddingsFor('marks');

  greenLog('Embeddings generated successfully!');
  exit(0);
}
