import 'package:flutter/material.dart';
import '../../service/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final service = AdminService();

  double revenue = 0;
  int orders = 0;
  int products = 0;
  int users = 0;

  List<Map<String, dynamic>> recentOrders = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    final r = await service.getTodayRevenue();
    final o = await service.getTotalOrders();
    final p = await service.getTotalProducts();
    final u = await service.getTotalUsers();
    final recent = await service.getRecentOrders();

    setState(() {
      revenue = r;
      orders = o;
      products = p;
      users = u;
      recentOrders = recent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // METRICS
          Row(
            children: [
              _card("Revenue", "\$${revenue.toStringAsFixed(2)}"),
              _card("Orders", "$orders"),
            ],
          ),
          Row(
            children: [
              _card("Products", "$products"),
              _card("Users", "$users"),
            ],
          ),

          const SizedBox(height: 20),

          const Text("Recent Orders",
              style: TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          ...recentOrders.map((o) => Card(
                child: ListTile(
                  title: Text("Order #${o['id']}"),
                  subtitle: Text("Status: ${o['status']}"),
                  trailing: Text("\$${o['total']}"),
                ),
              )),
        ],
      ),
    );
  }

  Widget _card(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}