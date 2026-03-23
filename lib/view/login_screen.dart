import 'package:flutter/material.dart';

import '../service/auth_service.dart';
import '../view/admin/admin_main_screen.dart';
import '../view/register_screen.dart';
import '../view/user/user_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool obscure = true;
  String error = '';
  void handleLogin() async {
    final username = usernameController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    final user = await authService.login(username, password);

    if (user == null) {
      setState(() {
        error = 'Sai tài khoản hoặc mật khẩu';
      });
    } else {
      if (user.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminMainScreen(currentUser: user)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserMainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // IMAGE
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage(
                        "https://lh3.googleusercontent.com/aida-public/AB6AXuAdBpSR_LHCW1ViJ2PcnolUUlB0pTVKkUtW9PLhQlEmYMjjeRELLDXnSkEdNIHXQmaRAvVM8Ix4r0ik5LI6JZ_Kr3OVNaZscLxtkq0VuDEUGEW4DyICt7Ddktwtb3PVuDV5N34WMbfEFWij9kFveb8MT62R1B-FIQzVCeONfcijQWr5u4do9wMRUMHp7XUuU1H5hNYB92m0jmGEobeWBcK_OA-i3208nrUTEvk9xcIBpbJikUeu1lkSCGP-wBSTFucKaCY1KMJCn78",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Welcome Back",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  "Login to your account to continue shopping",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // USERNAME
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: "Email or Username",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscure = !obscure;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Tài khoản mẫu: admin/1 và user/2",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 20),

                // BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff135bec),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Log In"),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    );
                  },
                  child: const Text("Bạn chưa có tài khoản? Đăng ký"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
