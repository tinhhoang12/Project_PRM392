import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/user.dart';
import '../../service/user_service.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import 'user_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({
    super.key,
    this.customerOnly = false,
  });

  final bool customerOnly;

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final userService = UserService();
  List<User> users = [];
  String keyword = '';

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await userService.getAllUsers();
    if (!mounted) return;
    setState(() {
      users = widget.customerOnly
          ? data.where((u) => u.role == 'user').toList()
          : data.where((u) => u.role != 'admin' && u.role != 'staff').toList();
    });
  }

  Future<void> _deleteUser(User user) async {
    await userService.deleteUser(user.id!);
    await loadUsers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = users.where((u) {
      final target = '${u.fullName ?? ''} ${u.email ?? ''} ${u.username}'.toLowerCase();
      return target.contains(keyword.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: Text(widget.customerOnly ? 'Customer Management' : 'Users'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF135BEC),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddUserScreen(allowedRoles: ['user']),
            ),
          );

          if (result == true) {
            await loadUsers();
          }
        },
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => keyword = value),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final u = filtered[index];
                return _userItem(u);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _userItem(User u) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: u.avatar != null
              ? (u.avatar!.startsWith('/')
                  ? FileImage(File(u.avatar!))
                  : NetworkImage(u.avatar!) as ImageProvider)
              : null,
          child: u.avatar == null ? const Icon(Icons.person) : null,
        ),
        title: Text(u.fullName ?? u.username),
        subtitle: Text(u.email ?? ''),
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserDetailScreen(user: u)),
                );
                await loadUsers();
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditUserScreen(
                      user: u,
                      allowedRoles: const ['user'],
                    ),
                  ),
                );
                if (result == true) {
                  await loadUsers();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(u),
            ),
          ],
        ),
      ),
    );
  }
}
