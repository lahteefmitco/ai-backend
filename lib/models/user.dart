class User {
  const User({
    required this.username, required this.password, this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  final int? id;
  final String username;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
    };
  }
}
