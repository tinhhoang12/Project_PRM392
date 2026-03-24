  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import '../../entity/user.dart';
  import '../../service/user_service.dart';

  class EditUserScreen extends StatefulWidget {
    final User user;
    final List<String> allowedRoles;

    const EditUserScreen({
      super.key,
      required this.user,
      this.allowedRoles = const ['user', 'staff', 'admin'],
    });

    @override
    State<EditUserScreen> createState() => _EditUserScreenState();
  }

  class _EditUserScreenState extends State<EditUserScreen> {
  late TextEditingController phoneController;
    String? role;
    String? avatarPath;
    File? imageFile;
    final userService = UserService();

    late TextEditingController usernameController;
    late TextEditingController emailController;
    late TextEditingController fullNameController;

    @override
    void initState() {
      super.initState();

      usernameController =
          TextEditingController(text: widget.user.username);
      emailController =
          TextEditingController(text: widget.user.email);
      fullNameController =
          TextEditingController(text: widget.user.fullName);

    phoneController = TextEditingController(text: widget.user.phone);

      role = widget.allowedRoles.contains(widget.user.role)
          ? widget.user.role
          : widget.allowedRoles.first;
      avatarPath = widget.user.avatar;
      if (avatarPath != null && avatarPath!.startsWith('/')) {
        imageFile = File(avatarPath!);
      }
    }

    Future pickImage() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          imageFile = File(picked.path);
          avatarPath = picked.path;
        });
      }
    }

    void handleUpdate() async {
      final updatedRole = widget.allowedRoles.length > 1
          ? (role ?? widget.user.role)
          : widget.user.role;

      final updatedUser = User(
        id: widget.user.id,
        username: usernameController.text,
        password: widget.user.password, // giữ nguyên
        email: emailController.text,
        fullName: fullNameController.text,
        phone: phoneController.text,
        avatar: avatarPath,
        role: updatedRole,
        isActive: widget.user.isActive,
        createdAt: widget.user.createdAt,
      );

      await userService.updateUser(updatedUser);

      Navigator.pop(context, true); // trả về true để reload
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Edit User")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile!)
                        : (avatarPath != null && avatarPath!.isNotEmpty && !avatarPath!.startsWith('/')
                            ? NetworkImage(avatarPath!) as ImageProvider
                            : null),
                    child: (imageFile == null && (avatarPath == null || avatarPath!.isEmpty))
                        ? const Icon(Icons.camera_alt)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                if (widget.allowedRoles.length > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: widget.allowedRoles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r[0].toUpperCase() + r.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        role = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: handleUpdate,
                  child: const Text("Update"),
                )
              ],
            ),
          ),
        ),
      );
    }
  }
