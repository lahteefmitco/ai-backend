import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

class DatabaseClient {
  DatabaseClient._internal();
  static final DatabaseClient _instance = DatabaseClient._internal();
  Connection? _connection;

  factory DatabaseClient() {
    return _instance;
  }

  Future<Connection> get connection async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }
    _connection = await _initConnection();
    return _connection!;
  }

  Future<Connection> _initConnection() async {
    // Load .env from the 'env' directory
    final envFile = File('env/.env');
    final env = DotEnv(includePlatformEnvironment: true)..load([envFile.path]);

    final host = env['DB_HOST'] ?? 'localhost';
    final port = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
    final databaseName = env['DB_NAME'] ?? 'postgres';
    final user = env['DB_USER'] ?? 'postgres';
    final password = env['DB_PASSWORD'] ?? 'password';

    print("Database Client initialized => $host:$port as $user, $databaseName");

    print('Connecting to database $databaseName at $host:$port as $user');

    return await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: databaseName,
        username: user,
        password: password,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable,
      ),
    );
  }

  Future<void> ensureTablesExist() async {
    final conn = await connection;

    // Create Students Table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        age INT NOT NULL,
        grade TEXT NOT NULL
      );
    ''');

    // Create Subjects Table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS subjects (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        code TEXT NOT NULL
      );
    ''');

    // Create Marks Table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS marks (
        id SERIAL PRIMARY KEY,
        student_id INT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        subject_id INT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
        score DECIMAL NOT NULL
      );
    ''');

    // Create Fees Table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS fees (
        id SERIAL PRIMARY KEY,
        student_id INT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
        amount DECIMAL NOT NULL,
        status TEXT NOT NULL
      );
    ''');

    // Create Users Table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      );
    ''');

    print('Tables initialized');
  }
}
