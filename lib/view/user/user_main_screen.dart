import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'product_category_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'order_history_screen.dart';
import '../../service/auth_service.dart';
import '../login_screen.dart';

class UserMainScreen extends StatefulWidget {
  final int initialIndex;

  const UserMainScreen({super.key, this.initialIndex = 0});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  late int currentIndex;
  int? userId;
  List<Widget> screens = [];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex.clamp(0, 4);
    _initUser();
  }

  Future<void> _initUser() async {
    final id = await AuthService().getCurrentUserId();
    if (!mounted) return;
    setState(() {
      userId = id;
      screens = [
        const HomeScreen(),
        const ProductCategoryScreen(),
        const CartScreen(),
        UserOrderHistoryScreen(userId: id),
        const ProfileScreen(),
      ];
    });
  }

  Future<void> _goToLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    await _initUser();
  }

  Future<bool> _showLoginRequiredDialog() async {
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to login to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Go to login'),
          ),
        ],
      ),
    );
    return goToLogin ?? false;
  }

  Future<void> _handleTabTap(int index) async {
    final restrictedTabs = <int>{2, 3, 4}; // Cart, Orders, Profile
    if (!restrictedTabs.contains(index)) {
      setState(() {
        currentIndex = index;
      });
      return;
    }

    final id = await AuthService().getCurrentUserId();
    if (id == null) {
      if (!mounted) return;
      final shouldGo = await _showLoginRequiredDialog();
      if (shouldGo) {
        await _goToLogin();
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      userId = id;
      currentIndex = index;
      screens[3] = UserOrderHistoryScreen(userId: id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens.isNotEmpty ? screens[currentIndex] : const SizedBox(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _handleTabTap(index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Category",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Orders",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
