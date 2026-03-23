import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/order.dart';
import '../../service/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService();
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final orderId = widget.order.id;
    if (orderId == null) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }

    final data = await _orderService.getOrderItems(orderId);
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: Text('Order #${order.id}'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _orderSummary(order),
                const SizedBox(height: 12),
                _shippingInfo(order),
                const SizedBox(height: 12),
                _itemsCard(),
              ],
            ),
    );
  }

  Widget _orderSummary(Order order) {
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
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _line('Status', _displayStatus(order)),
          _line('Payment Method', order.paymentMethod ?? '-'),
          _line('Payment Status', order.paymentStatus ?? 'pending'),
          _line('Subtotal', '\$${(order.subtotal ?? 0).toStringAsFixed(2)}'),
          _line(
              'Discount', '-\$${(order.discountAmount ?? 0).toStringAsFixed(2)}'),
          _line('Shipping Fee', '\$${(order.shippingFee ?? 0).toStringAsFixed(2)}'),
          const Divider(height: 18),
          _line(
            'Total',
            '\$${(order.total ?? 0).toStringAsFixed(2)}',
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _shippingInfo(Order order) {
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
          const Text(
            'Receiver Information',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _line('Name', order.receiverName ?? '-'),
          _line('Phone', order.receiverPhone ?? '-'),
          _line('Address', order.receiverAddress ?? '-'),
          _line('Created At', _formatDateTime(order.createdAt)),
        ],
      ),
    );
  }

  Widget _itemsCard() {
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
            'Items (${_items.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            const Text(
              'No order items found.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ..._items.map(_itemTile),
        ],
      ),
    );
  }

  Widget _itemTile(Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? 'Product #${item['product_id']}';
    final image = item['image']?.toString();
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final price = (item['price'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _image(image),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: $quantity',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Text(
            '\$${(price * quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF135BEC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(String? image) {
    if (image == null || image.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.image_not_supported, color: Color(0xFF94A3B8)),
      );
    }

    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _image(null),
      );
    }

    return Image.file(
      File(image),
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _image(null),
    );
  }

  Widget _line(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
                color: emphasize ? const Color(0xFF135BEC) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return raw ?? '-';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hh:$mm';
  }

  String _displayStatus(Order order) {
    final status = order.status ?? OrderService.pending;
    if (status == OrderService.delivered && (order.userReceivedConfirmed ?? 0) == 1) {
      return 'Successfully delivery';
    }
    return status;
  }
}
