import 'package:flutter/material.dart';

import '../../service/auth_service.dart';
import '../../service/cart_service.dart';
import '../../service/order_service.dart';
import 'user_main_screen.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  final int addressId;

  const CheckoutPaymentScreen({super.key, required this.addressId});

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  final orderService = OrderService();
  final cartService = CartService.instance;

  double total = 0;
  bool confirmedPaid = false;

  static const String qrImageUrl =
      'https://img.vietqr.io/image/MB-970422-compact2.png?amount=0&addInfo=ShopEase%20Payment&accountName=SHOP%20EASE';
  static const String qrOwnerName = 'SHOP EASE';
  static const String qrBankName = 'MB Bank';
  static const String qrAccountNumber = '970422';

  @override
  void initState() {
    super.initState();
    loadTotal();
  }

  Future<void> loadTotal() async {
    final cartItems = await cartService.getAll();
    double sum = 0;
    for (final item in cartItems) {
      sum += item.price * item.quantity;
    }
    if (!mounted) return;
    setState(() {
      total = sum;
    });
  }

  Future<void> _confirmPayment() async {
    if (!confirmedPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tick "I have completed QR transfer" first.')),
      );
      return;
    }

    final userId = await AuthService().getCurrentUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ban can dang nhap de dat hang!')),
      );
      return;
    }

    try {
      final orderId = await orderService.checkout(
        userId: userId,
        addressId: widget.addressId,
        paymentMethod: 'qr',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order #$orderId submitted.',
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const UserMainScreen(initialIndex: 3)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
              children: [
                _header(),
                const SizedBox(height: 14),
                const Text(
                  'QR Payment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scan this QR code with your banking app and complete transfer.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _qrCard(),
                const SizedBox(height: 16),
                _paymentInfoCard(),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: confirmedPaid,
                  onChanged: (value) {
                    setState(() {
                      confirmedPaid = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('I have completed QR transfer'),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  border: const Border(top: BorderSide(color: Color(0xffe5e7eb))),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF135bec),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'I Have Paid',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _confirmPayment,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Checkout',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _qrCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              qrImageUrl,
              width: 260,
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 260,
                height: 260,
                color: const Color(0xFFF1F5F9),
                alignment: Alignment.center,
                child: const Text(
                  'QR image not found\nPlease update qrImageUrl',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Scan QR to transfer',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _paymentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer Information',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _line('Bank', qrBankName),
          _line('Account No', qrAccountNumber),
          _line('Account Name', qrOwnerName),
          _line('Amount', '\$${total.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _line(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              key,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
