/// A class representing a student.
class Student {

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as int?,
      name: json['name'] as String,
      age: json['age'] as int,
      grade: json['grade'] as String,
      religion: json['religion'] as String?,
      address: json['address'] as String?,
      sex: json['sex'] as String?,
    );
  }
  /// Creates a [Student] instance.
  Student({
    required this.name, required this.age, required this.grade, this.id,
    this.religion,
    this.address,
    this.sex,
  });

  final int? id;
  final String name;
  final int age;
  final String grade;
  final String? religion;
  final String? address;
  final String? sex;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'age': age,
      'grade': grade,
      if (religion != null) 'religion': religion,
      if (address != null) 'address': address,
      if (sex != null) 'sex': sex,
    };
  }
}
