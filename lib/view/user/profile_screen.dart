import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import '../../service/user_service.dart';
import '../../entity/user.dart';
import 'edit_profile_screen.dart';
import '../login_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final currentUser = await UserService().getCurrentUser();
    setState(() {
      user = currentUser;
      loading = false;
    });
  }

  Future<void> logout() async {
    await AuthService().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : user == null
                ? const Center(child: Text('No user found'))
                : Column(
                    children: [
                      // HEADER
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Profile',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // AVATAR
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: (user!.avatar != null &&
                                user!.avatar!.isNotEmpty)
                            ? NetworkImage(user!.avatar!)
                            : const NetworkImage(
                                'https://i.pravatar.cc/300'),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        user!.fullName ?? 'No Name',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      Text(
                        user!.email ?? 'No Email',
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _menuItem("Edit Profile", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProfileScreen(user: user!),
                                ),
                              ).then((_) => loadUser());
                            }),

                            _menuItem("Logout", logout, isLogout: true),
                          ],
                        ),
                      )
                    ],
                  ),
      ),
    );
  }

  Widget _menuItem(String title, VoidCallback onTap,
      {bool isLogout = false}) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        textColor: isLogout ? Colors.red : null,
      ),
    );
  }
}