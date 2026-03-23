import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'product_category_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'order_status_screen.dart';
import '../../service/auth_service.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int currentIndex = 0;
  int? userId;
  List<Widget> screens = [];

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final id = await AuthService().getCurrentUserId();
    setState(() {
      userId = id;
      screens = [
        const HomeScreen(),
        const ProductCategoryScreen(),
        const CartScreen(),
        OrderStatusScreen(userId: id),
        const ProfileScreen(),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens.isNotEmpty ? screens[currentIndex] : const SizedBox(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
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