import 'package:postgres/postgres.dart';
import 'package:ai_backend/database/database_client.dart';
import 'package:ai_backend/models/mark.dart';

class MarkRepository {
  final DatabaseClient _dbClient = DatabaseClient();

  Future<List<Mark>> getAllMarks() async {
    final conn = await _dbClient.connection;
    final result = await conn.execute('SELECT * FROM marks');
    return result.map(_mapRowToMark).toList();
  }

  Future<List<Mark>> getMarksByStudentId(int studentId) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named('SELECT * FROM marks WHERE student_id = @student_id'),
      parameters: {'student_id': studentId},
    );
    return result.map(_mapRowToMark).toList();
  }

  Future<Mark> createMark(Mark mark) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO marks (student_id, subject_id, score) VALUES (@student_id, @subject_id, @score) RETURNING id',
      ),
      parameters: {
        'student_id': mark.studentId,
        'subject_id': mark.subjectId,
        'score': mark.score,
      },
    );
    final id = result.first[0]! as int;
    return Mark(
        id: id,
        studentId: mark.studentId,
        subjectId: mark.subjectId,
        score: mark.score,);
  }

  Future<Mark?> updateMark(int id, Mark mark) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'UPDATE marks SET student_id = @student_id, subject_id = @subject_id, score = @score WHERE id = @id RETURNING *',
      ),
      parameters: {
        'id': id,
        'student_id': mark.studentId,
        'subject_id': mark.subjectId,
        'score': mark.score,
      },
    );
    if (result.isEmpty) return null;
    return _mapRowToMark(result.first);
  }

  Future<void> deleteMark(int id) async {
    final conn = await _dbClient.connection;
    await conn.execute(
      Sql.named('DELETE FROM marks WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Mark _mapRowToMark(List<dynamic> row) {
    final map = (row as ResultRow).toColumnMap();
    return Mark(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      subjectId: map['subject_id'] as int,
      score: (map['score'] is String)
          ? double.parse(map['score'] as String)
          : (map['score'] as num).toDouble(),
    );
  }
}
