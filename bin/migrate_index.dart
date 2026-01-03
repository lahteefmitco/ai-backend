import 'package:ai_backend/database/database_client.dart';
import 'package:ai_backend/util/log_functions.dart';

void main() async {
  final dbClient = DatabaseClient();
  infoLog('Running database migration...');
  await dbClient.ensureTablesExist();
  greenLog('Migration completed.');
}
