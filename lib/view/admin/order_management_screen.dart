import '../../service/user_service.dart';
import 'package:flutter/material.dart';
import '../../entity/order.dart';
import '../../service/order_service.dart';
import 'order_history_screen.dart';
import 'dart:io';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final userService = UserService();
  Map<int, String> userNames = {}; // userId -> fullName
  final orderService = OrderService();
  List<Order> orders = [];
  Map<int, Map<String, dynamic>?> orderFirstProduct = {}; // orderId -> {name, image}

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  void loadOrders() async {
    final data = await orderService.getOrders();
    Map<int, Map<String, dynamic>?> firstProductMap = {};
    Map<int, String> userNameMap = {};
    for (final order in data) {
      final items = await orderService.getOrderItems(order.id!);
      if (items.isNotEmpty) {
        firstProductMap[order.id!] = items.first;
      } else {
        firstProductMap[order.id!] = null;
      }
      // Lấy tên user nếu cần
      if (order.customerName == null && order.userId != null) {
        if (!userNameMap.containsKey(order.userId)) {
          final user = await userService.getUserById(order.userId!);
          userNameMap[order.userId!] = user?.fullName ?? 'User #${order.userId}';
        }
      }
    }
    setState(() {
      orders = data;
      orderFirstProduct = firstProductMap;
      userNames = userNameMap;
    });
  }

  double get totalRevenue {
    return orders.fold(0, (sum, o) => sum + (o.total ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text("Order Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Category',
            onPressed: () {
              // TODO: Add category management navigation if needed
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Order History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSummary(),
          const SizedBox(height: 10),
          ...orders.map((o) => _orderCard(o)).toList(),
        ],
      ),
    );
  }

  // SUMMARY
  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _box("Today's Orders", "${orders.length}", true),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _box("Total Revenue", "\$${totalRevenue.toStringAsFixed(2)}", false),
        ),
      ],
    );
  }

  Widget _box(String title, String value, bool highlight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.blue : Colors.black,
            ),
          )
        ],
      ),
    );
  }

  // ORDER CARD
  Widget _orderCard(Order o) {
    final firstProduct = orderFirstProduct[o.id ?? -1];
    Widget? productImageWidget;
    String? productName;
    if (firstProduct != null) {
      productName = firstProduct['name']?.toString();
    }
  // Lấy tên user đặt hàng
  String displayUser = o.customerName ?? (o.userId != null ? (userNames[o.userId!] ?? 'User #${o.userId}') : '');
  // Lấy địa chỉ giao hàng
  String displayAddress = o.address ?? '';
  // Lấy phương thức thanh toán
  String displayPayment = o.paymentMethod ?? '';
    if (firstProduct != null && firstProduct['image'] != null && firstProduct['image'].toString().isNotEmpty) {
      final img = firstProduct['image'] as String;
      if (img.startsWith('http')) {
        productImageWidget = Image.network(img, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
      } else {
        final file = File(img);
        productImageWidget = FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.data == true) {
                return Image.file(file, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
              } else {
                return const Icon(Icons.broken_image, size: 60, color: Colors.grey);
              }
            }
            return const SizedBox(width: 60, height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
          },
        );
      }
    } else {
      productImageWidget = const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  productImageWidget,
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("#ORD-${o.id}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (productName != null) Text(productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 4),
                      Text(displayUser, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      if (displayAddress.isNotEmpty)
                        Text('Địa chỉ: $displayAddress', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (displayPayment.isNotEmpty)
                        Text('Thanh toán: $displayPayment', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text("Items • ${o.createdAt}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("\$${o.total}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 4),
                  Text(o.status ?? '', style: const TextStyle(fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _changeStatus(o);
            },
            child: const Text("Change Status"),
          )
        ],
      ),
    );
  }

  void _changeStatus(Order o) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ["Pending", "Completed", "Cancelled"]
            .map((s) => ListTile(
                  title: Text(s),
                  onTap: () async {
                    await orderService.updateStatus(o.id!, s);
                    Navigator.pop(context);
                    loadOrders();
                  },
                ))
            .toList(),
      ),
    );
  }
}