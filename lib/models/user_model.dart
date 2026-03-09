import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String name;
  final DateTime createdAt;
  final List<String> bookmarks;

  UserModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.createdAt,
    this.bookmarks = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookmarks: List<String>.from(data['bookmarks'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'bookmarks': bookmarks,
    };
  }

  UserModel copyWith({
    String? name,
    List<String>? bookmarks,
  }) {
    return UserModel(
      userId: userId,
      email: email,
      name: name ?? this.name,
      createdAt: createdAt,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}
