import 'package:flutter/material.dart';
import 'dart:io';
import '../../entity/user.dart';
import 'edit_user_screen.dart';

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text("User Detail"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
      // AVATAR
      CircleAvatar(
        radius: 50,
        backgroundImage: user.avatar != null
          ? (user.avatar!.startsWith('/')
            ? FileImage(File(user.avatar!))
            : NetworkImage(user.avatar!) as ImageProvider)
          : null,
        child: user.avatar == null
          ? const Icon(Icons.person, size: 50)
          : null,
      ),

            const SizedBox(height: 16),

            Text(
              user.fullName ?? 'No Name',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),

            Text(
              user.role.toUpperCase(),
              style: const TextStyle(
                  color: Color(0xff135bec),
                  fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            _infoCard("Username", user.username),
            _infoCard("Email", user.email),
            _infoCard("Phone", user.phone),
            _infoCard("Address", user.address),
            _infoCard("Created At", user.createdAt),

            const SizedBox(height: 20),

            // BUTTON ACTION
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditUserScreen(user: user),
                        ),
                      );
                      if (result == true) {
                        // Có thể reload lại thông tin user ở đây nếu muốn
                        // setState(() {});
                        Navigator.pop(context, true); // trả về true để màn trước reload
                      }
                    },
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    onPressed: () {
                      // TODO: delete user
                    },
                    child: const Text("Delete"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String? value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
          children: [
            TextSpan(
              text: value ?? 'N/A',
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.normal),
            )
          ],
        ),
      ),
    );
  }
}