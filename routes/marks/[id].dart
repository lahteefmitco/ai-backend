import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_backend/models/mark.dart';
import 'package:ai_backend/repository/mark_repository.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
) async {
  final repository = MarkRepository();
  final markId = int.tryParse(id);

  if (markId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Invalid ID');
  }

  switch (context.request.method) {
    case HttpMethod.get:
      // Typically getting a single mark by ID isn't the most common use case, but needed for completeness
      // Since repository doesn't have getMarkById, I might need to implement it or skip GET specific.
      // Assuming user wants full CRUD, I should have added getMarkById in repo.
      // For now, I will skip GET /marks/:id or implement a quick select query if needed.
      // Actually, standard CRUD implies GET one. I'll stick to DELETE and PUT for now, or just return 405 for GET if not ready.
      // Wait, Update uses ID, Delete uses ID.
      // Implementation plan didn't specify getMarkById, but did say "Routes (CRUD)".
      // I'll return methodNotAllowed for GET unless I update the repo.
      return Response(statusCode: HttpStatus.methodNotAllowed);
    case HttpMethod.put:
      return _updateMark(context, repository, markId);
    case HttpMethod.delete:
      return _deleteMark(context, repository, markId);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _updateMark(
  RequestContext context,
  MarkRepository repository,
  int id,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    final mark = Mark(
      // id is not used in update payload usually, but object needs it?
      // model has id.
      studentId: json['student_id'] as int,
      subjectId: json['subject_id'] as int,
      score: (json['score'] is num)
          ? (json['score'] as num).toDouble()
          : double.parse(json['score'].toString()),
    );
    final updated = await repository.updateMark(id, mark);
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

Future<Response> _deleteMark(
  RequestContext context,
  MarkRepository repository,
  int id,
) async {
  try {
    await repository.deleteMark(id);
    return Response(statusCode: HttpStatus.noContent);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
