/// A class representing a student.
class Student {
  /// Creates a [Student] instance.
  Student({
    this.id,
    required this.name,
    required this.age,
    required this.grade,
  });

  final int? id;
  final String name;
  final int age;
  final String grade;

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int?,
      name: json['name'] as String,
      age: json['age'] as int,
      grade: json['grade'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'age': age,
      'grade': grade,
    };
  }
}
