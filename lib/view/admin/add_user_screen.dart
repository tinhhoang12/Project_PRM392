import 'package:flutter/material.dart';
import '../../entity/user.dart';
import '../../service/user_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({
    super.key,
    this.allowedRoles = const ['user', 'staff', 'admin'],
  });

  final List<String> allowedRoles;

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final phoneController = TextEditingController();
  Future pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }
  final userService = UserService();
  File? imageFile;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final fullNameController = TextEditingController();

  late String role;

  @override
  void initState() {
    super.initState();
    role = widget.allowedRoles.contains('user')
        ? 'user'
        : widget.allowedRoles.first;
  }

  Future<void> handleAddUser() async {
    if (usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username & Password required")),
      );
      return;
    }

    final user = User(
      username: usernameController.text,
      password: passwordController.text,
      fullName: fullNameController.text,
      email: emailController.text,
      phone: phoneController.text,
      avatar: imageFile?.path, // 🔥 QUAN TRỌNG
      role: role,
      createdAt: DateTime.now().toString(),
    );

    try {
      await userService.insertUser(user);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username already exists")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add User"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    imageFile != null ? FileImage(imageFile!) : null,
                child: imageFile == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _input(usernameController, "Username"),
            _input(passwordController, "Password", isPassword: true),
            _input(emailController, "Email"),
            _input(fullNameController, "Full Name"),
            _input(phoneController, "Phone"),

            const SizedBox(height: 12),

            // ROLE DROPDOWN
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
                  role = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: handleAddUser,
                child: const Text("Add User"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
