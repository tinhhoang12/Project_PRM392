import 'package:flutter/material.dart';

import '../../entity/user.dart';
import 'admin_dashboard.dart';
import 'admin_profile_screen.dart';
import 'category_management_screen.dart';
import 'inventory_management_screen.dart';
import 'order_management_screen.dart';
import 'product_management_screen.dart';
import 'staff_management_screen.dart';
import 'user_management_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final User currentUser;

  const AdminMainScreen({super.key, required this.currentUser});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int currentIndex = 0;

  late final List<Widget> screens;
  late final List<BottomNavigationBarItem> items;

  bool get isAdmin => widget.currentUser.role == 'admin';

  @override
  void initState() {
    super.initState();

    if (isAdmin) {
      screens = [
        const AdminDashboardScreen(),
        const StaffManagementScreen(),
        AdminProfileScreen(user: widget.currentUser),
      ];

      items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard, size: 26),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.badge, size: 26),
          label: 'Staff',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, size: 26),
          label: 'Profile',
        ),
      ];
    } else {
      screens = [
        const ProductManagementScreen(),
        const OrderManagementScreen(),
        const UserManagementScreen(customerOnly: true),
        const InventoryManagementScreen(),
        const CategoryManagementScreen(),
        AdminProfileScreen(user: widget.currentUser),
      ];

      items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory, size: 26),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart, size: 26),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people, size: 26),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2, size: 26),
          label: 'Inventory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category, size: 26),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, size: 26),
          label: 'Profile',
        ),
      ];
    }
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
          boxShadow: const [
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
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            showUnselectedLabels: true,
            items: items,
          ),
        ),
      ),
    );
  }
}
