import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_backend/models/subject.dart';
import 'package:ai_backend/repository/subject_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final repository = SubjectRepository();

  switch (context.request.method) {
    case HttpMethod.get:
      return _getSubjects(context, repository);
    case HttpMethod.post:
      return _createSubject(context, repository);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getSubjects(
  RequestContext context,
  SubjectRepository repository,
) async {
  try {
    final subjects = await repository.getAllSubjects();
    return Response.json(body: subjects);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _createSubject(
  RequestContext context,
  SubjectRepository repository,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    final subject = Subject(
      name: json['name'] as String,
      code: json['code'] as String,
    );
    final created = await repository.createSubject(subject);
    return Response.json(
      statusCode: HttpStatus.created,
      body: created,
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.toString()},
    );
  }
}
