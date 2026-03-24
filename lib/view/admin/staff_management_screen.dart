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
    final all = await userService.getAllUsers(includeInactive: true);
    if (!mounted) return;
    setState(() {
      staffs = all.where((u) => u.role == 'staff').toList();
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
      isActive: user.isActive,
      createdAt: user.createdAt,
    );

    await userService.updateUser(updated);
    await loadStaffs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.username} role changed to $nextRole')),
    );
  }

  Future<void> _toggleActive(User user) async {
    final isActive = (user.isActive ?? 1) == 1;
    if (isActive) {
      await userService.deactivateUser(user.id!);
    } else {
      await userService.activateUser(user.id!);
    }
    await loadStaffs();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isActive
              ? 'Account deactivated successfully'
              : 'Account activated successfully',
        ),
      ),
    );
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
                final isActive = (u.isActive ?? 1) == 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Opacity(
                    opacity: isActive ? 1 : 0.55,
                    child: ListTile(
                      title: Text(u.fullName ?? u.username),
                      subtitle: Text(
                        '${u.email ?? ''}\nRole: ${u.role}${isActive ? '' : '\nStatus: Inactive'}',
                      ),
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
                            tooltip: isActive
                                ? 'Deactivate account'
                                : 'Activate account',
                            onPressed: () => _toggleActive(u),
                            icon: Icon(
                              isActive ? Icons.person_off : Icons.person_add_alt_1,
                              color: isActive ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
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
