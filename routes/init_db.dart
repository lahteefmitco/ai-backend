import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import '../lib/database/database_client.dart';

Future<Response> onRequest(RequestContext context) async {
  try {
    print('Initializing database tables...');
    final dbClient = DatabaseClient();
    await dbClient.ensureTablesExist();
    return Response(body: 'Database tables initialized successfully.');
  } catch (e) {
    return Response(
        statusCode: HttpStatus.internalServerError,
        body: 'Failed to initialize DB: $e');
  }
}
