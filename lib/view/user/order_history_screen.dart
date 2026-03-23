import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/order.dart';
import '../../service/auth_service.dart';
import '../../service/order_service.dart';
import 'order_detail_screen.dart';

class UserOrderHistoryScreen extends StatefulWidget {
  const UserOrderHistoryScreen({super.key, this.userId});

  final int? userId;

  @override
  State<UserOrderHistoryScreen> createState() => _UserOrderHistoryScreenState();
}

class _UserOrderHistoryScreenState extends State<UserOrderHistoryScreen> {
  final _orderService = OrderService();
  final _authService = AuthService();

  bool _loading = true;
  List<Order> _orders = [];
  Map<int, Map<String, dynamic>?> _firstItemByOrderId = {};
  final Set<int> _processingReceivedOrderIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    int? userId = widget.userId;
    userId ??= await _authService.getCurrentUserId();

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _orders = [];
        _loading = false;
      });
      return;
    }

    final orders = await _orderService.getOrdersByUser(userId);
    final firstItemMap = <int, Map<String, dynamic>?>{};

    for (final order in orders) {
      if (order.id == null) continue;
      final items = await _orderService.getOrderItems(order.id!);
      firstItemMap[order.id!] = items.isNotEmpty ? items.first : null;
    }

    if (!mounted) return;
    setState(() {
      _orders = orders;
      _firstItemByOrderId = firstItemMap;
      _loading = false;
    });
  }

  Future<void> _confirmReceived(Order order) async {
    if (order.id == null) return;

    final userId = widget.userId ?? await _authService.getCurrentUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue.')),
      );
      return;
    }

    setState(() {
      _processingReceivedOrderIds.add(order.id!);
    });

    try {
      await _orderService.confirmReceived(orderId: order.id!, userId: userId);
      await _loadOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${order.id} marked as successfully delivery.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _processingReceivedOrderIds.remove(order.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text('Order History'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_orders[index]);
                  },
                ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final item = _firstItemByOrderId[order.id ?? -1];
    final productName = item?['name']?.toString() ?? 'Order #${order.id}';
    final image = item?['image']?.toString();
    final status = _displayStatus(order);
    final statusStyle = _statusStyle(status);
    final isShipping = order.status == OrderService.shipping;
    final isProcessing = order.id != null && _processingReceivedOrderIds.contains(order.id);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6E8EC)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildImage(image),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusStyle.bg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusStyle.fg,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: .3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#ORD-${order.id}',
                            style: const TextStyle(
                              color: Color(0xFF9AA1AC),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(order.createdAt)} - \$${(order.total ?? 0).toStringAsFixed(2)}',
                        style:
                            const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFCBD0D8)),
              ],
            ),
            if (isShipping) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : () => _confirmReceived(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Received',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? image) {
    if (image == null || image.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_not_supported, color: Color(0xFF9CA3AF)),
      );
    }

    if (image.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          image,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImage(null),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(image),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImage(null),
      ),
    );
  }

  String _displayStatus(Order order) {
    final status = order.status ?? OrderService.pending;
    if (status == OrderService.delivered && (order.userReceivedConfirmed ?? 0) == 1) {
      return 'Successfully delivery';
    }
    return status;
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'Successfully delivery':
        return const _StatusStyle(
          fg: Color(0xFF15803D),
          bg: Color(0xFFDCFCE7),
        );
      case OrderService.confirmed:
        return const _StatusStyle(
          fg: Color(0xFF1D4ED8),
          bg: Color(0xFFDBEAFE),
        );
      case OrderService.shipping:
        return const _StatusStyle(
          fg: Color(0xFF135BEC),
          bg: Color(0xFFE7EEFF),
        );
      case OrderService.delivered:
        return const _StatusStyle(
          fg: Color(0xFF15803D),
          bg: Color(0xFFDCFCE7),
        );
      case OrderService.cancelled:
        return const _StatusStyle(
          fg: Color(0xFFB91C1C),
          bg: Color(0xFFFEE2E2),
        );
      default:
        return const _StatusStyle(
          fg: Color(0xFFB45309),
          bg: Color(0xFFFEF3C7),
        );
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _StatusStyle {
  const _StatusStyle({required this.fg, required this.bg});

  final Color fg;
  final Color bg;
}
