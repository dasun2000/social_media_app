import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications 🔔', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
      ),
      body: userProvider.getUser == null 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('targetUid', isEqualTo: userProvider.getUser!.id)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Something went wrong 😿"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No new notifications! ✨", style: TextStyle(color: Colors.grey, fontSize: 16)));
              }

              // Fix missing index by sorting locally
              var docs = snapshot.data!.docs;
              docs.sort((a, b) => (b.data()['timestamp'] as Timestamp).compareTo(a.data()['timestamp'] as Timestamp));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var notif = docs[index].data();
                  
                  // Mark as read immediately when viewed (Optional simple logic)
                  if (notif['isRead'] == false) {
                    docs[index].reference.update({'isRead': true});
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(text: "${notif['sourceUsername']} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: notif['message']),
                        ]
                      ),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(notif['timestamp'].toDate()),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                },
              );
            },
          ),
    );
  }
}
