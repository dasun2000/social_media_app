import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'chat_screen.dart';
import 'direct_message_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages 💌', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF6C63FF),
              child: Icon(Icons.public, color: Colors.white),
            ),
            title: const Text("Global Community Chat", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Chat with everyone magically ✨"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChatScreen()));
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Direct Messages", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: FirebaseFirestore.instance.collection('users').get(),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                // Filter out current user from the list
                var users = snapshot.data!.docs.where((doc) => doc.id != userProvider.getUser?.id).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var userData = users[index].data();
                    
                    ImageProvider avatarImage;
                    String url = userData['profilePhotoUrl'] ?? "https://via.placeholder.com/150";
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
                      title: Text(userData['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Tap to message! 🐾"),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => DirectMessageScreen(
                            targetUid: users[index].id,
                            targetUsername: userData['username'],
                          )
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
