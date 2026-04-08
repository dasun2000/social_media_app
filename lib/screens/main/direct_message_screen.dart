import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class DirectMessageScreen extends StatefulWidget {
  final String targetUid;
  final String targetUsername;

  const DirectMessageScreen({Key? key, required this.targetUid, required this.targetUsername}) : super(key: key);

  @override
  State<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends State<DirectMessageScreen> {
  final TextEditingController _messageController = TextEditingController();

  String getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
  }

  void sendMessage(String currentUid) async {
    if (_messageController.text.trim().isEmpty) return;

    String text = _messageController.text;
    _messageController.clear();
    String chatRoomId = getChatRoomId(currentUid, widget.targetUid);

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'text': text,
      'senderUid': currentUid,
      'datePublished': DateTime.now(),
    });

    // Optionally update the main chat room doc to show latest message in an Inbox
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'users': [currentUid, widget.targetUid],
      'latestMessage': text,
      'lastUpdated': DateTime.now(),
      'unreadBy_${widget.targetUid}': true,
      'unreadBy_$currentUid': false,
    }, SetOptions(merge: true));
  }

  void markAsRead(String currentUid) async {
    String chatRoomId = getChatRoomId(currentUid, widget.targetUid);
    await FirebaseFirestore.instance.collection('chats').doc(chatRoomId).set({
      'unreadBy_$currentUid': false,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.getUser == null) return const Scaffold();
    
    String currentUid = userProvider.getUser!.id;
    String chatRoomId = getChatRoomId(currentUid, widget.targetUid);
    
    // Automatically mark as read when we open the screen
    markAsRead(currentUid);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.targetUsername, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('datePublished', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Say hi! 👋", style: TextStyle(fontSize: 18, color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var snap = snapshot.data!.docs[index].data();
                    bool isMe = currentUid == snap['senderUid'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF6C63FF) : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          snap['text'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
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
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200]!.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => sendMessage(currentUid),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFF6C63FF),
                    radius: 24,
                    child: Icon(Icons.send, color: Colors.white),
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
