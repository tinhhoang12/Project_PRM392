import 'package:flutter/material.dart';

import '../../entity/order.dart';
import '../../service/auth_service.dart';
import '../../service/order_service.dart';

class OrderStatusScreen extends StatefulWidget {
  final int? userId;
  const OrderStatusScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final orderService = OrderService();
  final authService = AuthService();

  List<Order> orders = [];
  bool loading = true;
  final Set<int> _processingOrderIds = <int>{};

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
      final currentUserId = await authService.getCurrentUserId();
      if (currentUserId == null) {
        data = [];
      } else {
        data = await orderService.getOrdersByUser(currentUserId);
      }
    }

    if (!mounted) return;
    setState(() {
      orders = data;
      loading = false;
    });
  }

  Future<void> _confirmReceived(Order order) async {
    if (order.id == null) return;

    final currentUserId = widget.userId ?? await authService.getCurrentUserId();
    if (currentUserId == null) return;

    setState(() {
      _processingOrderIds.add(order.id!);
    });

    try {
      await orderService.confirmReceived(orderId: order.id!, userId: currentUserId);
      await loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _processingOrderIds.remove(order.id!);
      });
    }
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
                    final isShipping = order.status == OrderService.shipping;
                    final isProcessing = order.id != null && _processingOrderIds.contains(order.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Order #${order.id}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date: ${order.createdAt ?? ''}'),
                                  Text('Total: ${order.total != null ? order.total!.toStringAsFixed(2) : '0.00'}'),
                                  Text('Status: ${order.status}'),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                            if (isShipping)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isProcessing ? null : () => _confirmReceived(order),
                                  child: isProcessing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Received'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
