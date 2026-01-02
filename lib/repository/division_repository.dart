import 'package:postgres/postgres.dart';
import '../database/database_client.dart';
import '../models/division.dart';

class DivisionRepository {
  final DatabaseClient _dbClient = DatabaseClient();

  Future<List<Division>> getAllDivisions() async {
    final conn = await _dbClient.connection;
    final result = await conn.execute('SELECT * FROM divisions');
    return result.map((row) => _mapRowToDivision(row)).toList();
  }

  Future<Division?> getDivisionById(int id) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named('SELECT * FROM divisions WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _mapRowToDivision(result.first);
  }

  Future<Division> createDivision(Division division) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO divisions (name) VALUES (@name) RETURNING id',
      ),
      parameters: {
        'name': division.name,
      },
    );
    final id = result.first[0] as int;
    return Division(id: id, name: division.name);
  }

  Future<Division?> updateDivision(int id, Division division) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'UPDATE divisions SET name = @name WHERE id = @id RETURNING *',
      ),
      parameters: {
        'id': id,
        'name': division.name,
      },
    );
    if (result.isEmpty) return null;
    return _mapRowToDivision(result.first);
  }

  Future<void> deleteDivision(int id) async {
    final conn = await _dbClient.connection;
    await conn.execute(
      Sql.named('DELETE FROM divisions WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Division _mapRowToDivision(List<dynamic> row) {
    final map = (row as ResultRow).toColumnMap();
    return Division(
      id: map['id'] as int?,
      name: map['name'] as String,
    );
  }
}
