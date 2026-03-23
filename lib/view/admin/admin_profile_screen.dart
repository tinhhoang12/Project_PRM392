import 'dart:io';
import 'package:flutter/material.dart';
import '../../entity/user.dart';
import '../../service/user_service.dart';
import 'edit_user_screen.dart';
import '../../view/login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  final User user;

  const AdminProfileScreen({super.key, required this.user});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final userService = UserService();

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text("Admin Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(user),
            _contact(user),
            _permission(),
            _transaction(),
            _logout(),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header(User user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: user.avatar != null
                ? FileImage(File(user.avatar!))
                : null,
            child:
                user.avatar == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 10),

          Text(
            user.fullName ?? '',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(
            user.role == 'admin' ? "Administrator" : "User",
            style: const TextStyle(color: Colors.blue),
          ),

          const SizedBox(height: 8),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("Active",
                style: TextStyle(fontSize: 12)),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditUserScreen(user: user),
                      ),
                    );
                    if (result == true) {
                      setState(() {}); // reload lại thông tin nếu cần
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  label: const Text("Delete"),
                  onPressed: () async {
                    await userService.deleteUser(user.id!);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ================= CONTACT =================
  Widget _contact(User user) {
    return _section(
      title: "Contact Details",
      child: Column(
        children: [
          _item(Icons.email, "Email", user.email ?? ''),
          _item(Icons.phone, "Phone", user.phone ?? ''),
        ],
      ),
    );
  }

  // ================= PERMISSION =================
  Widget _permission() {
    return _section(
      title: "Permissions",
      child: Wrap(
        spacing: 8,
        children: [
          _chip("Inventory"),
          _chip("Orders"),
          _chip("Refund"),
          _chip("Reports", disabled: true),
        ],
      ),
    );
  }

  // ================= TRANSACTION =================
  Widget _transaction() {
    return _section(
      title: "Transactions",
      child: Column(
        children: [
          _transactionItem("Order #123", "Processing", "\$120"),
          _transactionItem("Bonus", "Done", "+\$50"),
        ],
      ),
    );
  }

  // ================= LOGOUT =================
  Widget _logout() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
        ),
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        label: const Text("Logout"),
      ),
    );
  }

  // ================= COMPONENT =================
  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          child
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  Widget _chip(String text, {bool disabled = false}) {
    return Chip(
      label: Text(text),
      backgroundColor:
          disabled ? Colors.grey.shade300 : Colors.grey.shade100,
    );
  }

  Widget _transactionItem(String title, String status, String price) {
    return ListTile(
      leading: const Icon(Icons.shopping_bag),
      title: Text(title),
      subtitle: Text(status),
      trailing: Text(price,
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}