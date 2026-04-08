import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'direct_message_screen.dart';
import '../../services/db_service.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String? uid;
  const ProfileScreen({Key? key, this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String uid = widget.uid ?? userProvider.getUser!.id;

      var userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      var postSnap = await FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: uid).get();

      userData = userSnap.data()!;
      postLen = postSnap.docs.length;
      followers = userSnap.data()!['followers'].length;
      following = userSnap.data()!['following'].length;
      isFollowing = userSnap.data()!['followers'].contains(userProvider.getUser!.id);
      
      setState(() {});
    } catch (e) {
      // Handle error
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(userData['username'] ?? 'Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: widget.uid == null || widget.uid == Provider.of<UserProvider>(context, listen: false).getUser!.id
            ? [
                IconButton(
                  icon: const Icon(Icons.palette_outlined),
                  onPressed: () => _showThemeBottomSheet(context),
                )
              ]
            : null,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        String url = userData['profilePhotoUrl'] ?? "https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_LdbmhiNM6Ypzb3FM4PPuFP9rHe7ri8Ju.jpg";
                        ImageProvider avatarImage;
                        if (url.startsWith('http')) {
                          avatarImage = NetworkImage(url);
                        } else {
                          try {
                            avatarImage = MemoryImage(base64Decode(url));
                          } catch (e) {
                            avatarImage = const NetworkImage("https://via.placeholder.com/150");
                          }
                        }
                        return CircleAvatar(
                          backgroundColor: Colors.grey,
                          backgroundImage: avatarImage,
                          radius: 40,
                        );
                      }
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildStatColumn(postLen, "posts"),
                              buildStatColumn(followers, "followers"),
                              buildStatColumn(following, "following"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              widget.uid == null || widget.uid == Provider.of<UserProvider>(context, listen: false).getUser!.id
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        buildButton(text: "Edit Profile", function: () async {
                                          bool? updated = await Navigator.of(context).push(MaterialPageRoute(
                                            builder: (context) => EditProfileScreen(
                                              currentBio: userData['bio'] ?? '', 
                                              currentPhotoUrl: userData['profilePhotoUrl'] ?? "https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_LdbmhiNM6Ypzb3FM4PPuFP9rHe7ri8Ju.jpg"
                                            )
                                          ));
                                          if (updated == true) {
                                            getData();
                                          }
                                        }),
                                        const SizedBox(width: 8),
                                        buildButton(text: "Sign Out", function: () async {
                                          await AuthService().signOut();
                                          if (context.mounted) {
                                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
                                          }
                                        }),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        isFollowing
                                          ? buildButton(text: "Unfollow", function: () async {
                                              await DBService().followUser(widget.uid!, Provider.of<UserProvider>(context, listen: false).getUser!.id);
                                              // We refresh immediately because setState in getData() will kick in.
                                              getData();
                                            })
                                          : buildButton(text: "Follow", function: () async {
                                              var userProvider = Provider.of<UserProvider>(context, listen: false);
                                              await DBService().followUser(widget.uid!, userProvider.getUser!.id);
                                              await DBService().createNotification(widget.uid!, userProvider.getUser!.id, userProvider.getUser!.username, "started following you. 🐾");
                                              getData();
                                            }),
                                        const SizedBox(width: 8),
                                        buildButton(text: "Message", function: () {
                                          Navigator.of(context).push(MaterialPageRoute(
                                            builder: (context) => DirectMessageScreen(
                                              targetUid: widget.uid!,
                                              targetUsername: userData['username'],
                                            )
                                          ));
                                        }),
                                      ],
                                    ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(userData['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(userData['bio'] ?? ''),
                ),
              ],
            ),
          ),
          const Divider(),
          FutureBuilder(
            future: FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: widget.uid ?? Provider.of<UserProvider>(context, listen: false).getUser!.id).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: (snapshot.data! as dynamic).docs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 1.5,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  DocumentSnapshot snap = (snapshot.data! as dynamic).docs[index];
                  if(snap['postUrl'] == "") return Container(color: Colors.grey[200]);
                  
                  String url = snap['postUrl'];
                  ImageProvider imageProvider;
                  if (url.startsWith('http')) {
                    imageProvider = NetworkImage(url);
                  } else {
                    try {
                      imageProvider = MemoryImage(base64Decode(url));
                    } catch(e) {
                      imageProvider = const NetworkImage("https://via.placeholder.com/150");
                    }
                  }

                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(num.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget buildButton({required String text, required Function()? function}) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      width: 120, // Reduced width to accommodate two buttons
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
        onPressed: function,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Appearance ✨', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Dark Mode 🌙', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    activeColor: themeProvider.seedColor,
                    onChanged: (val) {
                      themeProvider.toggleTheme(val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Accent Colors 🎨', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorCircle(themeProvider, const Color(0xFF6C63FF)), // Violet
                      _buildColorCircle(themeProvider, const Color(0xFFFF6584)), // Sunset Pink
                      _buildColorCircle(themeProvider, const Color(0xFF00B4D8)), // Ocean Mint
                      _buildColorCircle(themeProvider, const Color(0xFFF4A261)), // Peach
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildColorCircle(ThemeProvider provider, Color color) {
    bool isSelected = provider.seedColor.value == color.value;
    return GestureDetector(
      onTap: () => provider.changeSeedColor(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
