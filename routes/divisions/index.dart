import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:ai_backend/models/division.dart';
import 'package:ai_backend/repository/division_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final repository = DivisionRepository();

  switch (context.request.method) {
    case HttpMethod.get:
      return _getDivisions(context, repository);
    case HttpMethod.post:
      return _createDivision(context, repository);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getDivisions(
  RequestContext context,
  DivisionRepository repository,
) async {
  try {
    final divisions = await repository.getAllDivisions();
    return Response.json(body: divisions);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _createDivision(
  RequestContext context,
  DivisionRepository repository,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    final division = Division(
      name: json['name'] as String,
    );
    final created = await repository.createDivision(division);
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
