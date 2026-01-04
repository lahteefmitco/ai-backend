import 'dart:io';
import 'package:ai_backend/util/log_functions.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

class DatabaseClient {
  factory DatabaseClient() {
    return _instance;
  }
  DatabaseClient._internal();
  static final DatabaseClient _instance = DatabaseClient._internal();
  Connection? _connection;

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

    infoLog(
        'Database Client initialized => $host:$port as $user, $databaseName');

    infoLog('Connecting to database $databaseName at $host:$port as $user');

    return Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: databaseName,
        username: user,
        password: password,
      ),
      settings: const ConnectionSettings(
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
        grade TEXT NOT NULL,
        religion TEXT,
        address TEXT,
        sex TEXT
      );
    ''');

    // Migrate Students Table (add new columns if they don't exist)
    await conn.execute(
      'ALTER TABLE students ADD COLUMN IF NOT EXISTS religion TEXT;',
    );
    await conn
        .execute('ALTER TABLE students ADD COLUMN IF NOT EXISTS address TEXT;');
    await conn
        .execute('ALTER TABLE students ADD COLUMN IF NOT EXISTS sex TEXT;');

    // Create Divisions Table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS divisions (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL
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

    // Create Embeddings Table
    try {
      await conn.execute('CREATE EXTENSION IF NOT EXISTS vector;');
    } catch (e) {
      warningLog(
          'Vector extension creation failed (might already exist or not supported): $e');
    }

    // Determine dimension based on provider (this is a bit hacky but works for migration)
    final envFile = File('env/.env');
    final env = DotEnv(includePlatformEnvironment: true)..load([envFile.path]);
    final provider = env['AI_PROVIDER']?.toUpperCase() ?? 'OLLAMA';
    final dimension = provider == 'MISTRAL' ? 1024 : 768;

    infoLog(
        'Initializing Embeddings table for provider: $provider (Dim: $dimension)');

    await conn.execute('''
      CREATE TABLE IF NOT EXISTS embeddings (
        id SERIAL PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id INT NOT NULL,
        embedding vector($dimension),
        content TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        metadata JSONB
      );
    ''');

    // Migration logic for dimension change
    try {
      await conn.execute(
          'ALTER TABLE embeddings ALTER COLUMN embedding TYPE vector($dimension);');
    } catch (e) {
      warningLog(
          'Dimension mismatch detected (Target: $dimension). Truncating embeddings table...');
      await conn.execute('TRUNCATE TABLE embeddings;');
      await conn.execute('DROP INDEX IF EXISTS embeddings_embedding_idx;');
      await conn.execute(
          'ALTER TABLE embeddings ALTER COLUMN embedding TYPE vector($dimension);');
    }

    // Migrate Embeddings Table (add metadata if not exists)
    try {
      await conn.execute(
          'ALTER TABLE embeddings ADD COLUMN IF NOT EXISTS metadata JSONB;');
    } catch (e) {
      warningLog("Error adding metadata column (might already exist): $e");
    }

    // Create HNSW Index for Embeddings
    try {
      await conn.execute('''
        CREATE INDEX IF NOT EXISTS embeddings_embedding_idx 
        ON embeddings 
        USING hnsw (embedding vector_cosine_ops);
      ''');
      greenLog('HNSW Index initialized');
    } catch (e) {
      warningLog(
          'Error creating HNSW index (likely vector extension issue): $e');
    }

    greenLog('Tables initialized');
  }
}
