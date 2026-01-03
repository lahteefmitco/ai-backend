import 'dart:io';

import 'package:ai_backend/repository/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final username = body['username'] as String?;
  final password = body['password'] as String?;

  if (username == null ||
      password == null ||
      username.isEmpty ||
      password.isEmpty) {
    return Response(
        statusCode: HttpStatus.badRequest,
        body: 'Missing username or password',);
  }

  // Ideally we should inject the repository, but for simplicity we can instantiate it or get from context if we add middleware.
  // I will assume for now direct instantiation or context read if added.
  // Let's rely on middleware injection which I will add next.
  // But to be safe and sequential, I can read it if it exists or create one.
  // Wait, I planned to add `routes/_middleware.dart` later.
  // I will code this to look for the repository in the context.

  final repo = context.read<UserRepository>();

  final user = await repo.createUser(username: username, password: password);

  if (user == null) {
    return Response(
        statusCode: HttpStatus.conflict, body: 'User already exists',);
  }

  return Response.json(
      body: {'message': 'User created successfully', 'id': user.id},);
}
