import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/db_service.dart';
import 'package:intl/intl.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postAuthorUid;

  const CommentsScreen({Key? key, required this.postId, required this.postAuthorUid}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  void postComment() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (_commentController.text.trim().isEmpty) return;
    
    // Call DB Service
    await DBService().postComment(
      widget.postId,
      _commentController.text,
      userProvider.getUser!.id,
      userProvider.getUser!.username,
      userProvider.getUser!.profilePhotoUrl,
    );

    // Notify author
    await DBService().createNotification(
      widget.postAuthorUid,
      userProvider.getUser!.id,
      userProvider.getUser!.username,
      "commented: ${_commentController.text} 💬",
    );

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments 💭', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('datePublished', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No comments yet. Be the first! 🐾", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var snap = snapshot.data!.docs[index].data();
                    
                    ImageProvider avatarImage;
                    String url = snap['profilePic'] ?? "https://via.placeholder.com/150";
                    if (url.startsWith('http')) {
                      avatarImage = NetworkImage(url);
                    } else {
                      try {
                        avatarImage = MemoryImage(base64Decode(url));
                      } catch (e) {
                        avatarImage = const NetworkImage("https://via.placeholder.com/150");
                      }
                    }

                    return ListTile(
                      leading: CircleAvatar(backgroundImage: avatarImage),
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black87),
                          children: [
                            TextSpan(text: "${snap['username']} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: snap['text']),
                          ]
                        ),
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd().format(snap['datePublished'].toDate()),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200]!.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: postComment,
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFF6C63FF),
                    radius: 20,
                    child: Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
