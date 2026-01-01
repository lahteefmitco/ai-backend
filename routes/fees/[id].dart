import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../lib/models/fee.dart';
import '../../lib/repository/fee_repository.dart';

Future<Response> onRequest(
  RequestContext context,
  String id,
) async {
  final repository = FeeRepository();
  final feeId = int.tryParse(id);

  if (feeId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Invalid ID');
  }

  switch (context.request.method) {
    case HttpMethod.get:
      // Similar to Marks, skipping GET /fees/:id for now or implement later
      return Response(statusCode: HttpStatus.methodNotAllowed);
    case HttpMethod.put:
      return _updateFee(context, repository, feeId);
    case HttpMethod.delete:
      return _deleteFee(context, repository, feeId);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _updateFee(
  RequestContext context,
  FeeRepository repository,
  int id,
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
    final updated = await repository.updateFee(id, fee);
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

Future<Response> _deleteFee(
  RequestContext context,
  FeeRepository repository,
  int id,
) async {
  try {
    await repository.deleteFee(id);
    return Response(statusCode: HttpStatus.noContent);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': e.toString()},
    );
  }
}
