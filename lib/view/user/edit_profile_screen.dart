
import 'package:flutter/material.dart';
import '../../entity/user.dart';
import '../../service/user_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.user.fullName ?? '';
    emailController.text = widget.user.email ?? '';
    // Nếu avatar là local file, có thể parse ra _avatarFile
    if (widget.user.avatar != null && widget.user.avatar!.startsWith('/')) {
      _avatarFile = File(widget.user.avatar!);
    }
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  void save() async {
    final updatedUser = User(
      id: widget.user.id,
      fullName: nameController.text,
      email: emailController.text,
      avatar: _avatarFile?.path ?? widget.user.avatar,
      username: widget.user.username,
      password: widget.user.password,
      phone: widget.user.phone,
      role: widget.user.role,
    );

    await UserService().updateUser(updatedUser);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickAvatar,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _avatarFile != null
                    ? FileImage(_avatarFile!)
                    : (widget.user.avatar != null && widget.user.avatar!.isNotEmpty
                        ? NetworkImage(widget.user.avatar!)
                        : const NetworkImage('https://i.pravatar.cc/300')) as ImageProvider,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 10),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: save,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}