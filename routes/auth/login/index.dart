import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:ai_backend/repository/user_repository.dart';
import 'package:dotenv/dotenv.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final username = body['username'] as String?;
  final password = body['password'] as String?;

  if (username == null || password == null) {
    return Response(
        statusCode: HttpStatus.badRequest,
        body: 'Missing username or password');
  }

  final repo = context.read<UserRepository>();
  final user = await repo.getUserByUsername(username);

  if (user == null || !BCrypt.checkpw(password, user.password)) {
    return Response(
        statusCode: HttpStatus.unauthorized, body: 'Invalid credentials');
  }

  // Generate JWT
  final jwt = JWT(
    {
      'id': user.id,
      'username': user.username,
    },
  );

  // Load env
  try {
    final env = DotEnv(includePlatformEnvironment: true)..load(['env/.env']);
    final secret = env['JWT_SECRET'] ?? 'secret_key_change_this';

    final token = jwt.sign(
      SecretKey(secret),
      expiresIn: const Duration(hours: 1),
    );

    return Response.json(body: {'token': token});
  } catch (e, st) {
    print('Login error: $e\n$st');
    return Response(
        statusCode: HttpStatus.internalServerError, body: e.toString());
  }
}
