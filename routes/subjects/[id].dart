import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_backend/models/subject.dart';
import 'package:ai_backend/repository/subject_repository.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
) async {
  final repository = SubjectRepository();
  final subjectId = int.tryParse(id);

  if (subjectId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Invalid ID');
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _getSubject(context, repository, subjectId);
    case HttpMethod.put:
      return _updateSubject(context, repository, subjectId);
    case HttpMethod.delete:
      return _deleteSubject(context, repository, subjectId);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getSubject(
  RequestContext context,
  SubjectRepository repository,
  int id,
) async {
  try {
    final subject = await repository.getSubjectById(id);
    if (subject == null) {
      return Response(statusCode: HttpStatus.notFound);
    }
    return Response.json(body: subject);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _updateSubject(
  RequestContext context,
  SubjectRepository repository,
  int id,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    final subject = Subject(
      id: id,
      name: json['name'] as String,
      code: json['code'] as String,
    );
    final updated = await repository.updateSubject(id, subject);
    if (updated == null) {
      return Response(statusCode: HttpStatus.notFound);
    }
    return Response.json(body: updated);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _deleteSubject(
  RequestContext context,
  SubjectRepository repository,
  int id,
) async {
  try {
    await repository.deleteSubject(id);
    return Response(statusCode: HttpStatus.noContent);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
