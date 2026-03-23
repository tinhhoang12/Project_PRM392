import 'package:flutter/material.dart';
import '../../service/order_service.dart';
import '../../entity/order.dart';

class OrderStatusScreen extends StatefulWidget {
  final int? userId; // Nếu cần truyền userId
  const OrderStatusScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final orderService = OrderService();
  List<Order> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    List<Order> data;
    if (widget.userId != null) {
      data = await orderService.getOrdersByUser(widget.userId!);
    } else {
      data = await orderService.getOrders();
    }
    setState(() {
      orders = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Status')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('Order #${order.id}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${order.createdAt ?? ''}'),
                            Text('Total: ${order.total != null ? order.total!.toStringAsFixed(2) : '0.00'}'),
                            Text('Status: ${order.status}'),
                          ],
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Chuyển sang màn chi tiết đơn hàng nếu muốn
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
