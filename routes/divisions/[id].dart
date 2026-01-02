import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/models/division.dart';
import '../../lib/repository/division_repository.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
) async {
  final repository = DivisionRepository();
  final divisionId = int.tryParse(id);

  if (divisionId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Invalid ID');
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _getDivision(context, repository, divisionId);
    case HttpMethod.put:
      return _updateDivision(context, repository, divisionId);
    case HttpMethod.delete:
      return _deleteDivision(context, repository, divisionId);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getDivision(
  RequestContext context,
  DivisionRepository repository,
  int id,
) async {
  try {
    final division = await repository.getDivisionById(id);
    if (division == null) {
      return Response(
          statusCode: HttpStatus.notFound, body: 'Division not found');
    }
    return Response.json(body: division);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _updateDivision(
  RequestContext context,
  DivisionRepository repository,
  int id,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    final division = Division(
      name: json['name'] as String,
    );
    final updated = await repository.updateDivision(id, division);
    if (updated == null) {
      return Response(
          statusCode: HttpStatus.notFound, body: 'Division not found');
    }
    return Response.json(body: updated);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _deleteDivision(
  RequestContext context,
  DivisionRepository repository,
  int id,
) async {
  try {
    await repository.deleteDivision(id);
    return Response(statusCode: HttpStatus.noContent);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
