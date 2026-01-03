import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_backend/models/mark.dart';
import 'package:ai_backend/repository/mark_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final repository = MarkRepository();

  switch (context.request.method) {
    case HttpMethod.get:
      return _getMarks(context, repository);
    case HttpMethod.post:
      return _createMark(context, repository);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getMarks(
  RequestContext context,
  MarkRepository repository,
) async {
  try {
    // Check if filtering by student_id
    final params = context.request.uri.queryParameters;
    if (params.containsKey('student_id')) {
      final studentId = int.tryParse(params['student_id']!);
      if (studentId != null) {
        final marks = await repository.getMarksByStudentId(studentId);
        return Response.json(body: marks);
      }
    }

    final marks = await repository.getAllMarks();
    return Response.json(body: marks);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _createMark(
  RequestContext context,
  MarkRepository repository,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    final mark = Mark(
      studentId: json['student_id'] as int,
      subjectId: json['subject_id'] as int,
      score: (json['score'] is num)
          ? (json['score'] as num).toDouble()
          : double.parse(json['score'].toString()),
    );
    final created = await repository.createMark(mark);
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
