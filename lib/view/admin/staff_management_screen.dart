import 'package:flutter/material.dart';

import '../../entity/user.dart';
import '../../service/user_service.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final userService = UserService();
  List<User> staffs = [];
  String keyword = '';

  @override
  void initState() {
    super.initState();
    loadStaffs();
  }

  Future<void> loadStaffs() async {
    final all = await userService.getAllUsers();
    if (!mounted) return;
    setState(() {
      staffs = all.where((u) => u.role == 'staff' || u.role == 'admin').toList();
    });
  }

  Future<void> _toggleRole(User user) async {
    final nextRole = user.role == 'admin' ? 'staff' : 'admin';

    final updated = User(
      id: user.id,
      username: user.username,
      password: user.password,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      address: user.address,
      avatar: user.avatar,
      role: nextRole,
      createdAt: user.createdAt,
    );

    await userService.updateUser(updated);
    await loadStaffs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.username} role changed to $nextRole')),
    );
  }

  Future<void> _deleteUser(User user) async {
    await userService.deleteUser(user.id!);
    await loadStaffs();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = staffs.where((u) {
      final text = '${u.username} ${u.fullName ?? ''} ${u.email ?? ''}'.toLowerCase();
      return text.contains(keyword.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(title: const Text('Staff Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddUserScreen(allowedRoles: ['staff', 'admin']),
            ),
          );
          if (result == true) {
            await loadStaffs();
          }
        },
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => keyword = v),
              decoration: InputDecoration(
                hintText: 'Search staff by name/email',
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
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final u = filtered[index];
                final isAdmin = u.role == 'admin';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ListTile(
                    title: Text(u.fullName ?? u.username),
                    subtitle: Text('${u.email ?? ''}\nRole: ${u.role}'),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Toggle role admin/staff',
                          onPressed: () => _toggleRole(u),
                          icon: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.badge,
                            color: const Color(0xFF135BEC),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditUserScreen(
                                  user: u,
                                  allowedRoles: const ['staff', 'admin'],
                                ),
                              ),
                            );
                            if (result == true) {
                              await loadStaffs();
                            }
                          },
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () => _deleteUser(u),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
