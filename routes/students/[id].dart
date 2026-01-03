import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_backend/models/student.dart';
import 'package:ai_backend/repository/student_repository.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
) async {
  final repository = StudentRepository();
  final studentId = int.tryParse(id);

  if (studentId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Invalid ID');
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _getStudent(context, repository, studentId);
    case HttpMethod.put:
      return _updateStudent(context, repository, studentId);
    case HttpMethod.delete:
      return _deleteStudent(context, repository, studentId);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getStudent(
  RequestContext context,
  StudentRepository repository,
  int id,
) async {
  try {
    final student = await repository.getStudentById(id);
    if (student == null) {
      return Response(statusCode: HttpStatus.notFound);
    }
    return Response.json(body: student);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _updateStudent(
  RequestContext context,
  StudentRepository repository,
  int id,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    final student = Student(
      id: id,
      name: json['name'] as String,
      age: json['age'] as int,
      grade: json['grade'] as String,
    );
    final updated = await repository.updateStudent(id, student);
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

Future<Response> _deleteStudent(
  RequestContext context,
  StudentRepository repository,
  int id,
) async {
  try {
    await repository.deleteStudent(id);
    return Response(statusCode: HttpStatus.noContent);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
