import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../providers/user_provider.dart';
import '../../services/db_service.dart';
import 'package:intl/intl.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'comments_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect ✨', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('datePublished', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No posts found. 😿"));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              PostModel post = PostModel.fromDocument(snapshot.data!.docs[index]);
              return CutePostItem(post: post);
            },
          );
        },
      ),
    );
  }
}

class CutePostItem extends StatefulWidget {
  final PostModel post;
  const CutePostItem({Key? key, required this.post}) : super(key: key);

  @override
  State<CutePostItem> createState() => _CutePostItemState();
}

class _CutePostItemState extends State<CutePostItem> with SingleTickerProviderStateMixin {
  bool isLikeAnimating = false;
  bool isTapDown = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    Widget imageWidget;
    if (widget.post.postUrl.startsWith('http')) {
      imageWidget = Image.network(widget.post.postUrl, width: double.infinity, fit: BoxFit.cover, height: 250);
    } else {
      try {
        imageWidget = Image.memory(base64Decode(widget.post.postUrl), width: double.infinity, fit: BoxFit.cover, height: 250);
      } catch(e) {
        imageWidget = const Icon(Icons.error);
      }
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => isTapDown = true),
      onTapUp: (_) => setState(() => isTapDown = false),
      onTapCancel: () => setState(() => isTapDown = false),
      child: AnimatedScale(
        scale: isTapDown ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32), // Extremely round modern look
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                blurRadius: 25,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withAlpha(240),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProfileScreen(uid: widget.post.uid),
                  ));
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(widget.post.profilePhotoUrl),
                        radius: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.post.username,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
                    ),
                    const Spacer(),
                    if (userProvider.getUser?.id == widget.post.uid)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditDialog();
                          } else if (value == 'delete') {
                            await DBService().deletePost(widget.post.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Post'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete Post', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      )
                    else 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('✨', style: TextStyle(fontSize: 16)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (widget.post.postUrl.isNotEmpty) ...[
                GestureDetector(
                  onDoubleTap: () async {
                    if (userProvider.getUser != null) {
                      if (!widget.post.likes.contains(userProvider.getUser!.id)) {
                        DBService().createNotification(widget.post.uid, userProvider.getUser!.id, userProvider.getUser!.username, "liked your post! ❤️");
                      }
                      DBService().likePost(widget.post.id, userProvider.getUser!.id, widget.post.likes);
                      setState(() {
                        isLikeAnimating = true;
                      });
                      await Future.delayed(const Duration(milliseconds: 600));
                      if (mounted) {
                        setState(() {
                          isLikeAnimating = false;
                        });
                      }
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: imageWidget,
                      ),
                      AnimatedScale(
                        scale: isLikeAnimating ? 1.2 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isLikeAnimating ? 1 : 0,
                          child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 140),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        widget.post.likes.contains(userProvider.getUser?.id) ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(widget.post.likes.contains(userProvider.getUser?.id)),
                        color: widget.post.likes.contains(userProvider.getUser?.id) ? Colors.pinkAccent : Colors.grey[600],
                        size: 28,
                      ),
                    ),
                    onPressed: () async {
                       if (userProvider.getUser != null) {
                        if (!widget.post.likes.contains(userProvider.getUser!.id)) {
                          DBService().createNotification(widget.post.uid, userProvider.getUser!.id, userProvider.getUser!.username, "liked your post! ❤️");
                        }
                        DBService().likePost(widget.post.id, userProvider.getUser!.id, widget.post.likes);
                       }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text('${widget.post.likes.length} likes', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 16)),
                  const SizedBox(width: 20),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.maps_ugc_rounded, color: Colors.grey[600], size: 28),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CommentsScreen(
                          postId: widget.post.id,
                          postAuthorUid: widget.post.uid,
                        )
                      ));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.post.description,
                style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat.yMMMd().format(widget.post.datePublished),
                style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showEditDialog() {
    TextEditingController descController = TextEditingController(text: widget.post.description);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Post"),
          content: TextField(
            controller: descController,
            decoration: const InputDecoration(hintText: "Enter new description"),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await DBService().updatePost(widget.post.id, descController.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
