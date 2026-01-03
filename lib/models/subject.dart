class Subject {

  Subject({
    this.id,
    required this.name,
    required this.code,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int?,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
  final int? id;
  final String name;
  final String code;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'code': code,
    };
  }
}
