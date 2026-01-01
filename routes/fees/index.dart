import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/models/fee.dart';
import '../../lib/repository/fee_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final repository = FeeRepository();

  switch (context.request.method) {
    case HttpMethod.get:
      return _getFees(context, repository);
    case HttpMethod.post:
      return _createFee(context, repository);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _getFees(
  RequestContext context,
  FeeRepository repository,
) async {
  try {
    final params = context.request.uri.queryParameters;
    if (params.containsKey('student_id')) {
      final studentId = int.tryParse(params['student_id']!);
      if (studentId != null) {
        final fees = await repository.getFeesByStudentId(studentId);
        return Response.json(body: fees);
      }
    }

    final fees = await repository.getAllFees();
    return Response.json(body: fees);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}

Future<Response> _createFee(
  RequestContext context,
  FeeRepository repository,
) async {
  try {
    final json = await context.request.json() as Map<String, dynamic>;
    final fee = Fee(
      studentId: json['student_id'] as int,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.parse(json['amount'].toString()),
      status: json['status'] as String,
    );
    final created = await repository.createFee(fee);
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
