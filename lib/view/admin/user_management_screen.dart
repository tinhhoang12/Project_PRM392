import 'dart:io';

import 'package:flutter/material.dart';
import '../../entity/user.dart';
import '../../service/user_service.dart';
import 'add_user_screen.dart';
import 'user_detail_screen.dart';
import 'edit_user_screen.dart';
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Hàm xóa user và reload danh sách
  Future<void> _deleteUser(int id) async {
    await userService.deleteUser(id);
    loadUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deleted successfully")),
    );
  }
  final userService = UserService();
  List<User> users = [];
  List<User> filteredUsers = [];

  String selectedRole = 'staff'; // staff | user
  String keyword = '';

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  void loadUsers() async {
    final data = await userService.getAllUsers();
    users = data;
    applyFilter();
  }

  void applyFilter() {
    setState(() {
      filteredUsers = users.where((u) {
        final matchRole =
            selectedRole == 'staff' ? u.role == 'admin' : u.role == 'user';

        final matchSearch =
            (u.fullName ?? '').toLowerCase().contains(keyword.toLowerCase()) ||
            (u.email ?? '').toLowerCase().contains(keyword.toLowerCase());

        return matchRole && matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),

      // HEADER
      appBar: AppBar(
        title: const Text("Users"),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Color(0x20135bec),
              child: Icon(Icons.more_horiz, color: Color(0xff135bec)),
            ),
          )
        ],
      ),

      body: Column(
        children: [
          _buildSearch(),
          _buildToggle(),
          Expanded(child: _buildList()),
        ],
      ),

      // FLOAT BUTTON
     floatingActionButton: FloatingActionButton(
  backgroundColor: const Color(0xff135bec),
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddUserScreen(),
      ),
    );

    if (result == true) {
      loadUsers(); // reload list
    }
  },
  child: const Icon(Icons.person_add),
),
    );
  }

  // 🔍 SEARCH
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (value) {
          keyword = value;
          applyFilter();
        },
        decoration: InputDecoration(
          hintText: "Search by name or email",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // 🔄 TOGGLE STAFF / CUSTOMER
  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (selectedRole != 'staff') {
                    setState(() {
                      selectedRole = 'staff';
                    });
                    applyFilter();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedRole == 'staff' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "Staff",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedRole == 'staff' ? const Color(0xff135bec) : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (selectedRole != 'user') {
                    setState(() {
                      selectedRole = 'user';
                    });
                    applyFilter();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedRole == 'user' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "Customers",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selectedRole == 'user' ? const Color(0xff135bec) : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📋 LIST USER
  Widget _buildList() {
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final u = filteredUsers[index];
        return _userItem(u);
      },
    );
  }

  // 👤 USER ITEM
  Widget _userItem(User u) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: u.avatar != null
            ? (u.avatar!.startsWith('/')
                ? FileImage(File(u.avatar!))
                : NetworkImage(u.avatar!) as ImageProvider)
            : null,
        child: u.avatar == null ? const Icon(Icons.person) : null,
      ),
      title: Text(u.fullName ?? ''),
      subtitle: Text(u.email ?? ''),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailScreen(user: u),
                ),
              );
              loadUsers();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await userService.deleteUser(u.id!);
              loadUsers();
            },
          ),
        ],
      ),
    );
  }

  Widget _userInfo(User u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(u.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(u.role, style: const TextStyle(color: Color(0xff135bec), fontSize: 12, fontWeight: FontWeight.w600)),
        Text(u.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  void _confirmDelete(int userId) async {
    // Lấy user theo id
    final user = users.firstWhere((u) => u.id == userId);
    if (user.role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot delete admin")),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa người dùng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await userService.deleteUser(userId);
      loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa người dùng!')),
      );
    }
  }
}