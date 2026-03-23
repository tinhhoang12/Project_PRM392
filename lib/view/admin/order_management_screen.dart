import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/order.dart';
import '../../service/address_service.dart';
import '../../service/notification_service.dart';
import '../../service/order_service.dart';
import '../../service/user_service.dart';
import 'admin_notification_screen.dart';
import 'order_history_screen.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final userService = UserService();
  final addressService = AddressService();
  final orderService = OrderService();
  final notificationService = NotificationService.instance;

  Map<int, String> userNames = {};
  Map<int, String> addressById = {};
  List<Order> orders = [];
  Map<int, Map<String, dynamic>?> orderFirstProduct = {};
  int unreadNotificationCount = 0;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    loadOrders();
    _loadNotificationCount();
  }

  Future<void> loadOrders() async {
    final data = await orderService.getOrders();

    final firstProductMap = <int, Map<String, dynamic>?>{};
    final userNameMap = <int, String>{};
    final addressMap = <int, String>{};

    for (final order in data) {
      if (order.id == null) continue;

      final items = await orderService.getOrderItems(order.id!);
      firstProductMap[order.id!] = items.isNotEmpty ? items.first : null;

      if (order.userId != null && !userNameMap.containsKey(order.userId)) {
        final user = await userService.getUserById(order.userId!);
        userNameMap[order.userId!] = user?.fullName ?? 'User #${order.userId}';
      }

      if ((order.receiverAddress == null || order.receiverAddress!.isEmpty) &&
          order.addressId != null &&
          !addressMap.containsKey(order.addressId)) {
        final address = await addressService.getById(order.addressId!);
        if (address != null) {
          addressMap[order.addressId!] = address.address;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      orders = data;
      orderFirstProduct = firstProductMap;
      userNames = userNameMap;
      addressById = addressMap;
    });
  }

  Future<void> _loadNotificationCount() async {
    final currentUser = await userService.getCurrentUser();
    if (currentUser?.id == null || !mounted) return;
    final unread = await notificationService.getUnreadCount(userId: currentUser!.id!);
    if (!mounted) return;
    setState(() {
      _currentUserId = currentUser.id;
      unreadNotificationCount = unread;
    });
  }

  Future<void> _openNotifications() async {
    if (_currentUserId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminNotificationScreen(userId: _currentUserId!),
      ),
    );
    await _loadNotificationCount();
  }

  double get totalRevenue {
    return orders.fold(0, (sum, o) => sum + (o.total ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  _summary(),
                  const SizedBox(height: 12),
                  ...orders.map(_orderCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x1A135BEC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu, color: Color(0xFF135BEC)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Order Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: _openNotifications,
                icon: const Icon(Icons.notifications_none),
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      unreadNotificationCount > 99
                          ? '99+'
                          : '$unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
            icon: const Icon(Icons.history),
          )
        ],
      ),
    );
  }

  Widget _summary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            label: "Today's Orders",
            value: '${orders.length}',
            highlight: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            label: 'Total Revenue',
            value: '\$${totalRevenue.toStringAsFixed(2)}',
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: highlight ? const Color(0xFF135BEC) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(Order order) {
    final firstProduct = orderFirstProduct[order.id ?? -1];
    final image = firstProduct?['image']?.toString();

    final displayUser = order.userId != null
        ? (userNames[order.userId!] ?? 'User #${order.userId}')
        : 'Unknown User';
    final displayPayment = order.paymentMethod ?? 'N/A';
    final displayPaymentStatus = order.paymentStatus ?? 'pending';
    final displayAddress = (order.receiverAddress != null &&
            order.receiverAddress!.trim().isNotEmpty)
        ? order.receiverAddress!
        : (order.addressId != null ? (addressById[order.addressId!] ?? '-') : '-');
    final statusStyle = _statusStyle(order.status ?? OrderService.pending);
    final paymentStyle = _paymentStyle(displayPaymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '#ORD-${order.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusStyle.bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Order: ${order.status ?? OrderService.pending}',
                            style: TextStyle(
                              color: statusStyle.fg,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: paymentStyle.bg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Payment: $displayPaymentStatus',
                            style: TextStyle(
                              color: paymentStyle.fg,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayUser,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_timeAgo(order.createdAt)} • ${firstProduct == null ? 0 : 1} Items',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${(order.total ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF135BEC),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Method: $displayPayment',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _productImage(image),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _changeStatus(order),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Change Status',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _productImage(String? img) {
    if (img == null || img.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.image_not_supported, color: Color(0xFF94A3B8)),
      );
    }

    if (img.startsWith('http')) {
      return Image.network(
        img,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _productImage(null),
      );
    }

    return Image.file(
      File(img),
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _productImage(null),
    );
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case OrderService.confirmed:
        return const _StatusStyle(
          fg: Color(0xFF1D4ED8),
          bg: Color(0xFFDBEAFE),
        );
      case OrderService.shipping:
        return const _StatusStyle(
          fg: Color(0xFF0E7490),
          bg: Color(0xFFCFFAFE),
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

  _StatusStyle _paymentStyle(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const _StatusStyle(
          fg: Color(0xFF15803D),
          bg: Color(0xFFDCFCE7),
        );
      case 'pending':
      default:
        return const _StatusStyle(
          fg: Color(0xFFB45309),
          bg: Color(0xFFFEF3C7),
        );
    }
  }

  String _timeAgo(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return 'just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _changeStatus(Order order) {
    final currentStatus = order.status ?? OrderService.pending;
    final allowed = orderService.getAllowedStatusTransitions(currentStatus);

    if (allowed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order is in terminal state: $currentStatus')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: allowed
            .map(
              (status) => ListTile(
                title: Text(status),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  try {
                    await orderService.updateStatus(order.id!, status);
                    if (!mounted) return;
                    Navigator.pop(context);
                    loadOrders();
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({required this.fg, required this.bg});

  final Color fg;
  final Color bg;
}
