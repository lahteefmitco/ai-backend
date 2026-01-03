import 'package:postgres/postgres.dart';
import 'package:ai_backend/database/database_client.dart';
import 'package:ai_backend/models/subject.dart';

class SubjectRepository {
  final DatabaseClient _dbClient = DatabaseClient();

  Future<List<Subject>> getAllSubjects() async {
    final conn = await _dbClient.connection;
    final result = await conn.execute('SELECT * FROM subjects');
    return result.map(_mapRowToSubject).toList();
  }

  Future<Subject?> getSubjectById(int id) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named('SELECT * FROM subjects WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _mapRowToSubject(result.first);
  }

  Future<Subject> createSubject(Subject subject) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO subjects (name, code) VALUES (@name, @code) RETURNING id',
      ),
      parameters: {
        'name': subject.name,
        'code': subject.code,
      },
    );
    final id = result.first[0]! as int;
    return Subject(id: id, name: subject.name, code: subject.code);
  }

  Future<Subject?> updateSubject(int id, Subject subject) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'UPDATE subjects SET name = @name, code = @code WHERE id = @id RETURNING *',
      ),
      parameters: {
        'id': id,
        'name': subject.name,
        'code': subject.code,
      },
    );
    if (result.isEmpty) return null;
    return _mapRowToSubject(result.first);
  }

  Future<void> deleteSubject(int id) async {
    final conn = await _dbClient.connection;
    await conn.execute(
      Sql.named('DELETE FROM subjects WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Subject _mapRowToSubject(List<dynamic> row) {
    final map = (row as ResultRow).toColumnMap();
    return Subject(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String,
    );
  }
}
