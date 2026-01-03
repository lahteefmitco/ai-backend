class Fee { // 'paid', 'pending'

  Fee({
    this.id,
    required this.studentId,
    required this.amount,
    required this.status,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    return Fee(
      id: json['id'] as int?,
      studentId: json['student_id'] as int,
      amount: (json['amount'] is String)
          ? double.parse(json['amount'] as String)
          : (json['amount'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
  final int? id;
  final int studentId;
  final double amount;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'amount': amount,
      'status': status,
    };
  }
}
