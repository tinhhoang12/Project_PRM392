import 'package:flutter/material.dart';

import '../../entity/order.dart';
import '../../service/order_service.dart';
import '../../service/user_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final orderService = OrderService();
  final userService = UserService();
  List<Order> orders = [];
  Map<int, String> userNames = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  void loadOrders() async {
    setState(() {
      loading = true;
    });

    final data = await orderService.getOrders();
    final userIds = data.map((o) => o.userId).whereType<int>().toSet().toList();
    final names = <int, String>{};

    if (userIds.isNotEmpty) {
      final users = await userService.getAllUsers();
      for (final u in users) {
        if (u.id != null && userIds.contains(u.id)) {
          names[u.id!] = u.fullName ?? u.username;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      orders = data;
      userNames = names;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    final displayName = o.userId != null
                        ? (userNames[o.userId!] ?? 'User #${o.userId}')
                        : 'Unknown User';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('#ORD-${o.id} - $displayName'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${o.createdAt ?? ''}'),
                            Text('Status: ${o.status ?? ''}'),
                            Text(
                                'Total: \$${o.total?.toStringAsFixed(2) ?? '0.00'}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
