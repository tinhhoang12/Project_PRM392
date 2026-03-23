import 'package:flutter/material.dart';

import 'entity/user.dart';
import 'service/user_service.dart';
import 'view/admin/admin_main_screen.dart';
import 'view/user/user_main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  final _userService = UserService();

  Future<User?> _loadCurrentUser() {
    return _userService.getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _loadCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null && (user.role == 'admin' || user.role == 'staff')) {
          return AdminMainScreen(currentUser: user);
        }

        return const UserMainScreen();
      },
    );
  }
}
