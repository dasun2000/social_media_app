import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/db_service.dart';
import '../../utils/utils.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final String currentBio;
  final String currentPhotoUrl;

  const EditProfileScreen({Key? key, required this.currentBio, required this.currentPhotoUrl}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Uint8List? _image;
  bool _isLoading = false;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void selectImage() async {
    Uint8List img = await pickImage(ImageSource.gallery);
    setState(() {
      _image = img;
    });
  }

  void saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String res = await DBService().updateUserProfile(
      userProvider.getUser!.id,
      _bioController.text,
      _image,
    );

    if (res == "success") {
      await userProvider.refreshUser(); // Keep App State in sync
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        Navigator.pop(context, true); // True means it was updated
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        showSnackBar(context, res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider profileImage;
    if (_image != null) {
      profileImage = MemoryImage(_image!);
    } else if (widget.currentPhotoUrl.startsWith('http')) {
      profileImage = NetworkImage(widget.currentPhotoUrl);
    } else {
      try {
        profileImage = MemoryImage(base64Decode(widget.currentPhotoUrl));
      } catch (e) {
        profileImage = const NetworkImage("https://via.placeholder.com/150");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: saveProfile,
            child: const Text('Save', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profileImage,
                      ),
                      Positioned(
                        bottom: -10,
                        left: 60,
                        child: IconButton(
                          onPressed: selectImage,
                          icon: const Icon(Icons.add_a_photo),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Write something about yourself',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
    );
  }
}
