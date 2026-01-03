/// A class representing a division.
class Division {
  /// Creates a [Division] instance.
  Division({
    required this.name, this.id,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] as int?,
      name: json['name'] as String,
    );
  }

  final int? id;
  final String name;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
    };
  }
}
