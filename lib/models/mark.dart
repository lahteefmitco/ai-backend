class Mark {

  Mark({
    this.id,
    required this.studentId,
    required this.subjectId,
    required this.score,
  });

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      id: json['id'] as int?,
      studentId: json['student_id'] as int,
      subjectId: json['subject_id'] as int,
      score: (json['score'] is String)
          ? double.parse(json['score'] as String)
          : (json['score'] as num).toDouble(),
    );
  }
  final int? id;
  final int studentId;
  final int subjectId;
  final double score;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'subject_id': subjectId,
      'score': score,
    };
  }
}
