import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import 'package:flutter/foundation.dart';

class DBService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImageToStorage(String childName, File file, bool isPost) async {
    Reference ref = _storage.ref().child(childName).child(const Uuid().v1());
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload post
  Future<String> uploadPost(String description, File file, String uid, String username, String profImage) async {
    String res = "Some error occurred";
    try {
      String photoUrl = "https://images.unsplash.com/photo-1542393315-30fa39e0bd37"; // fallback
      if (!kIsWeb) {
        try {
          photoUrl = await uploadImageToStorage('posts', file, true);
        } catch (_) {} // Mocking or error uploading image shouldn't fully block for demo
      }

      String postId = const Uuid().v1();
      PostModel post = PostModel(
        id: postId,
        uid: uid,
        username: username,
        profilePhotoUrl: profImage,
        description: description,
        postUrl: photoUrl,
        datePublished: DateTime.now(),
        likes: [],
      );

      _firestore.collection('posts').doc(postId).set(post.toJson());
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
}
