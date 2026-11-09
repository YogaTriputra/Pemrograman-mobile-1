class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.companyName,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final String companyName;

  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final company = json['company'];
    if (json['id'] is! int ||
        json['name'] is! String ||
        json['username'] is! String ||
        json['email'] is! String ||
        json['phone'] is! String ||
        json['website'] is! String ||
        company is! Map<String, dynamic> ||
        company['name'] is! String) {
      throw const FormatException('Data pengguna tidak valid.');
    }

    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      companyName: company['name'] as String,
    );
  }
}
