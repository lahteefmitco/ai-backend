import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/models/student.dart';
import '../../lib/repository/student_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final repository = StudentRepository();
  // Initialize tables on first hitting any endpoint (lazy init) or dedicated init endpoint.
  // Ideally this should be done at server startup.

  switch (context.request.method) {
    case HttpMethod.get:
      return _getStudents(context, repository);
    case HttpMethod.post:
      return _createStudent(context, repository);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getStudents(
  RequestContext context,
  StudentRepository repository,
) async {
  try {
    final students = await repository.getAllStudents();
    return Response.json(body: students);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _createStudent(
  RequestContext context,
  StudentRepository repository,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    // Validate fields if necessary
    final student = Student(
      name: json['name'] as String,
      age: json['age'] as int,
      grade: json['grade'] as String,
    );
    final created = await repository.createStudent(student);
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
