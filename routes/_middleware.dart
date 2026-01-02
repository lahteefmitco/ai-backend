import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dotenv/dotenv.dart';

import 'package:ai_backend/repository/user_repository.dart';

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(provider<UserRepository>((_) => UserRepository()))
      .use(_authenticationMiddleware);
}

Handler _authenticationMiddleware(Handler handler) {
  return (context) async {
    final path = context.request.uri.path;

    // Allow auth routes to be accessed without token
    if (path.startsWith('/auth') || path == '/init_db') {
      return handler(context);
    }

    final authHeader = context.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(
          statusCode: HttpStatus.unauthorized,
          body: 'Missing or invalid token');
    }

    final token = authHeader.substring(7);

    // Load env
    final env = DotEnv(includePlatformEnvironment: true)..load(['env/.env']);
    final secret = env['JWT_SECRET'] ?? 'secret_key_change_this';

    try {
      JWT.verify(token, SecretKey(secret));
      return handler(context);
    } catch (_) {
      return Response(
          statusCode: HttpStatus.unauthorized,
          body: 'Invalid or expired token');
    }
  };
}
