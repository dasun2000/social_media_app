import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String bio;
  final String profilePhotoUrl;
  final List<String> followers;
  final List<String> following;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.bio,
    required this.profilePhotoUrl,
    required this.followers,
    required this.following,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel(
      id: doc.id,
      email: doc['email'] ?? '',
      username: doc['username'] ?? '',
      bio: doc['bio'] ?? '',
      profilePhotoUrl: doc['profilePhotoUrl'] ?? '',
      followers: List<String>.from(doc['followers'] ?? []),
      following: List<String>.from(doc['following'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'bio': bio,
      'profilePhotoUrl': profilePhotoUrl,
      'followers': followers,
      'following': following,
    };
  }
}
