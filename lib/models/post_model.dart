import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String uid;
  final String username;
  final String profilePhotoUrl;
  final String description;
  final String postUrl;
  final DateTime datePublished;
  final List<String> likes;

  PostModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.profilePhotoUrl,
    required this.description,
    required this.postUrl,
    required this.datePublished,
    required this.likes,
  });

  factory PostModel.fromDocument(DocumentSnapshot doc) {
    return PostModel(
      id: doc['postId'] ?? doc.id,
      uid: doc['uid'] ?? '',
      username: doc['username'] ?? '',
      profilePhotoUrl: doc['profilePhotoUrl'] ?? '',
      description: doc['description'] ?? '',
      postUrl: doc['postUrl'] ?? '',
      datePublished: (doc['datePublished'] as Timestamp).toDate(),
      likes: List<String>.from(doc['likes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': id,
      'uid': uid,
      'username': username,
      'profilePhotoUrl': profilePhotoUrl,
      'description': description,
      'postUrl': postUrl,
      'datePublished': datePublished,
      'likes': likes,
    };
  }
}
