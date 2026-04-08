import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';

class DBService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // We are completely bypassing Firebase Storage to make this 100% free!
  // Images will be converted into string text (base64) so it fits in the Database directly.
  Future<String> uploadPost(String description, Uint8List fileBytes, String uid, String username, String profImage) async {
    String res = "Some error occurred";
    try {
      // Convert the image bytes directly to a String using Base64
      String base64ImageString = base64Encode(fileBytes);

      String postId = const Uuid().v1();
      PostModel post = PostModel(
        id: postId,
        uid: uid,
        username: username,
        profilePhotoUrl: profImage,
        description: description,
        postUrl: base64ImageString, // Save the string data directly!
        datePublished: DateTime.now(),
        likes: [],
      );

      await _firestore.collection('posts').doc(postId).set(post.toJson());
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> likePost(String postId, String uid, List likes) async {
    try {
      if (likes.contains(uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([uid])
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([uid])
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> followUser(String targetUid, String currentUserUid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(targetUid).get();
      List followers = (doc.data()! as dynamic)['followers'];

      if (followers.contains(currentUserUid)) {
        await _firestore.collection('users').doc(targetUid).update({
          'followers': FieldValue.arrayRemove([currentUserUid])
        });
        await _firestore.collection('users').doc(currentUserUid).update({
          'following': FieldValue.arrayRemove([targetUid])
        });
      } else {
        await _firestore.collection('users').doc(targetUid).update({
          'followers': FieldValue.arrayUnion([currentUserUid])
        });
        await _firestore.collection('users').doc(currentUserUid).update({
          'following': FieldValue.arrayUnion([targetUid])
        });
      }
      } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String> updateUserProfile(String uid, String bio, Uint8List? fileBytes) async {
    String res = "Some error occurred";
    try {
      Map<String, dynamic> updateData = {'bio': bio};
      
      if (fileBytes != null) {
        String base64ImageString = base64Encode(fileBytes);
        updateData['profilePhotoUrl'] = base64ImageString;
      }

      await _firestore.collection('users').doc(uid).update(updateData);
      res = "success";
    } catch (err) {
      res = err.toString();
    }
    return res;
  }

  Future<void> createNotification(String targetUid, String sourceUid, String sourceUsername, String actionMessage) async {
    try {
      if (targetUid == sourceUid) return; // Don't notify yourself
      
      await _firestore.collection('notifications').add({
        'targetUid': targetUid,
        'sourceUid': sourceUid,
        'sourceUsername': sourceUsername,
        'message': actionMessage,
        'timestamp': DateTime.now(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> postComment(String postId, String text, String uid, String username, String profilePic) async {
    try {
      if (text.trim().isNotEmpty) {
        String commentId = const Uuid().v1();
        await _firestore.collection('posts').doc(postId).collection('comments').doc(commentId).set({
          'profilePic': profilePic,
          'username': username,
          'uid': uid,
          'text': text,
          'commentId': commentId,
          'datePublished': DateTime.now(),
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
