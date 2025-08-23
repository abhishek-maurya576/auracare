class UserModel {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic>? preferences;
  final List<String>? interests;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferences,
    this.interests,
  });

  // Getter for compatibility with Firebase Auth
  String get uid => id;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      preferences: json['preferences'] as Map<String, dynamic>?,
      interests: json['interests'] != null 
          ? List<String>.from(json['interests'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'preferences': preferences,
      'interests': interests,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    List<String>? interests,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      interests: interests ?? this.interests,
    );
  }
}

