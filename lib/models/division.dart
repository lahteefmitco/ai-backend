/// A class representing a division.
class Division {
  /// Creates a [Division] instance.
  Division({
    this.id,
    required this.name,
  });

  final int? id;
  final String name;

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] as int?,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
    };
  }
}
