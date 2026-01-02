import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

import '../database/database_client.dart';
import '../models/user.dart';

class UserRepository {
  Future<User?> createUser({
    required String username,
    required String password,
  }) async {
    final client = DatabaseClient();
    final conn = await client.connection;

    // Hash the password
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    try {
      final result = await conn.execute(
        Sql.named(
          'INSERT INTO users (username, password) VALUES (@username, @password) RETURNING id',
        ),
        parameters: {
          'username': username,
          'password': hashedPassword,
        },
      );

      final row = result.first;
      return User(
        id: row[0] as int,
        username: username,
        password: hashedPassword,
      );
    } catch (_) {
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    final client = DatabaseClient();
    final conn = await client.connection;

    final result = await conn.execute(
      Sql.named('SELECT * FROM users WHERE username = @username'),
      parameters: {'username': username},
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;
    // Map the row data (Postgres returns List<dynamic> by default for simple execute,
    // but column structure depends on driver version.
    // Assuming row structure: id, username, password based on CREATE.
    return User(
      id: row[0] as int,
      username: row[1] as String,
      password: row[2] as String,
    );
  }
}
