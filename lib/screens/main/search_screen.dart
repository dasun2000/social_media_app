import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isShowUsers = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for a user... 🔍',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200]!.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          ),
          onFieldSubmitted: (String _) {
            setState(() {
              isShowUsers = true;
            });
          },
          onChanged: (String val) {
            if (val.isEmpty) {
              setState(() {
                isShowUsers = false;
              });
            } else {
               setState(() {
                isShowUsers = true;
               });
            }
          },
        ),
      ),
      body: isShowUsers
          ? FutureBuilder(
              future: FirebaseFirestore.instance.collection('users').get(),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter locally to support simple partial and case-insensitive matching
                var filteredUsers = snapshot.data!.docs.where((doc) {
                  String username = doc.data()['username'].toString().toLowerCase();
                  return username.contains(_searchController.text.toLowerCase());
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("No users found. 😿"));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var userData = filteredUsers[index].data();
                    
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
                      leading: CircleAvatar(
                        backgroundImage: avatarImage,
                        radius: 20,
                      ),
                      title: Text(userData['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("View Profile ✨"),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ProfileScreen(uid: filteredUsers[index].id),
                        ));
                      },
                    );
                  },
                );
              },
            )
          : const Center(
              child: Text(
                "Find your friends! 🐾",
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            ),
    );
  }
}
