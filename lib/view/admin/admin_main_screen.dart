import 'package:flutter/material.dart';
import 'product_management_screen.dart';
import 'admin_dashboard.dart';
import 'order_management_screen.dart';
import 'user_management_screen.dart';
import 'admin_profile_screen.dart';
import 'category_management_screen.dart';


import '../../entity/user.dart';

class AdminMainScreen extends StatefulWidget {
  final User currentUser;

  const AdminMainScreen({super.key, required this.currentUser});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      const AdminDashboardScreen(),
      const ProductManagementScreen(),
      const OrderManagementScreen(),
      const UserManagementScreen(),
       const CategoryManagementScreen(),
      AdminProfileScreen(user: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey[500],
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard, size: 28),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory, size: 28),
                label: "Products",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart, size: 28),
                label: "Orders",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people, size: 28),
                label: "Users",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.category, size: 28),
                label: "Categories",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, size: 28),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}