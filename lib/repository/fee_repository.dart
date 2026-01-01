import 'package:postgres/postgres.dart';
import '../database/database_client.dart';
import '../models/fee.dart';

class FeeRepository {
  final DatabaseClient _dbClient = DatabaseClient();

  Future<List<Fee>> getAllFees() async {
    final conn = await _dbClient.connection;
    final result = await conn.execute('SELECT * FROM fees');
    return result.map((row) => _mapRowToFee(row)).toList();
  }

  Future<List<Fee>> getFeesByStudentId(int studentId) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named('SELECT * FROM fees WHERE student_id = @student_id'),
      parameters: {'student_id': studentId},
    );
    return result.map((row) => _mapRowToFee(row)).toList();
  }

  Future<Fee> createFee(Fee fee) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'INSERT INTO fees (student_id, amount, status) VALUES (@student_id, @amount, @status) RETURNING id',
      ),
      parameters: {
        'student_id': fee.studentId,
        'amount': fee.amount,
        'status': fee.status,
      },
    );
    final id = result.first[0] as int;
    return Fee(
        id: id,
        studentId: fee.studentId,
        amount: fee.amount,
        status: fee.status);
  }

  Future<Fee?> updateFee(int id, Fee fee) async {
    final conn = await _dbClient.connection;
    final result = await conn.execute(
      Sql.named(
        'UPDATE fees SET student_id = @student_id, amount = @amount, status = @status WHERE id = @id RETURNING *',
      ),
      parameters: {
        'id': id,
        'student_id': fee.studentId,
        'amount': fee.amount,
        'status': fee.status,
      },
    );
    if (result.isEmpty) return null;
    return _mapRowToFee(result.first);
  }

  Future<void> deleteFee(int id) async {
    final conn = await _dbClient.connection;
    await conn.execute(
      Sql.named('DELETE FROM fees WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Fee _mapRowToFee(List<dynamic> row) {
    final map = (row as ResultRow).toColumnMap();
    return Fee(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      amount: (map['amount'] is String)
          ? double.parse(map['amount'] as String)
          : (map['amount'] as num).toDouble(),
      status: map['status'] as String,
    );
  }
}
