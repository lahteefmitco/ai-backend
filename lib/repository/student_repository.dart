import 'package:postgres/postgres.dart';
import '../database/database_client.dart';
import '../models/student.dart';

class StudentRepository {
  final DatabaseClient _dbClient = DatabaseClient();

  Future<List<Student>> getAllStudents() async {
    final conn = await _dbClient.connection;
    final result = await conn.execute('SELECT * FROM students');
    return result.map((row) => _mapRowToStudent(row)).toList();
  }

  Future<Student?> getStudentById(int id) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named('SELECT * FROM students WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _mapRowToStudent(result.first);
  }

  Future<Student> createStudent(Student student) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO students (name, age, grade, religion, address, sex) VALUES (@name, @age, @grade, @religion, @address, @sex) RETURNING id',
      ),
      parameters: {
        'name': student.name,
        'age': student.age,
        'grade': student.grade,
        'religion': student.religion,
        'address': student.address,
        'sex': student.sex,
      },
    );
    final id = result.first[0] as int;
    return Student(
      id: id,
      name: student.name,
      age: student.age,
      grade: student.grade,
      religion: student.religion,
      address: student.address,
      sex: student.sex,
    );
  }

  Future<Student?> updateStudent(int id, Student student) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'UPDATE students SET name = @name, age = @age, grade = @grade, religion = @religion, address = @address, sex = @sex WHERE id = @id RETURNING *',
      ),
      parameters: {
        'id': id,
        'name': student.name,
        'age': student.age,
        'grade': student.grade,
        'religion': student.religion,
        'address': student.address,
        'sex': student.sex,
      },
    );
    if (result.isEmpty) return null;
    return _mapRowToStudent(result.first);
  }

  Future<void> deleteStudent(int id) async {
    final conn = await _dbClient.connection;
    await conn.execute(
      Sql.named('DELETE FROM students WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Student _mapRowToStudent(List<dynamic> row) {
    // row is [id, name, age, grade] based on select * order or schema
    // To be safer, we can map by column name if using mapped results, but postgres package returns List<dynamic> for simple queries or ResultRow
    // Let's assume ResultRow matches key access if access by name is available, but the driver often returns lists by default unless configured.
    // Actually, modern postgres driver 'execute' returns Result which is iterable of ResultRow. ResultRow can be accessed by column name if available in the query metadata.
    // But 'SELECT *' usually works. Let's try to access by index or convert to map if possible.
    // ResultRow acts like a map.

    // We should use the toColumnMap() if available or just access by dict.
    // Checking documentation style: row.toColumnMap()
    // However, let's verify if row is ResultRow. Yes.

    final map = (row as ResultRow).toColumnMap();
    return Student(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int,
      grade: map['grade'] as String,
      religion: map['religion'] as String?,
      address: map['address'] as String?,
      sex: map['sex'] as String?,
    );
  }
}
