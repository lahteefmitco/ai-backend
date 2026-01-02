import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'lib/database/database_client.dart';

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  final dbClient = DatabaseClient();
  await dbClient.ensureTablesExist();

  return serve(handler, ip, port);
}
