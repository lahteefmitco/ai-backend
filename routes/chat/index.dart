import 'dart:async';
import 'dart:io';

import 'package:ai_backend/managers/rag_manager.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json();
  final message = body['message'] as String?;

  if (message == null || message.isEmpty) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Message is required'},
    );
  }

  try {
    final ragManager = RagManager();
    final answer = await ragManager.askQuestion(message);

    return Response.json(
      body: {'response': answer},
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Internal Server Error: $e'},
    );
  }
}
