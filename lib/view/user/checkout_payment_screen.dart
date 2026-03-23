import 'checkout_success_screen.dart';
import 'package:flutter/material.dart';



import '../../service/auth_service.dart';
import '../../service/order_service.dart';
import '../../service/cart_service.dart';
import '../../service/product_service.dart';


class CheckoutPaymentScreen extends StatefulWidget {
  final int addressId;
  const CheckoutPaymentScreen({Key? key, required this.addressId}) : super(key: key);

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  String selectedPayment = "card";
  final orderService = OrderService();
  final cartService = CartService.instance;
  final productService = ProductService();
  double total = 0;
  String promoCode = "";
  double saving = 42.0; // demo value

  @override
  void initState() {
    super.initState();
    loadTotal();
  }

  Future<void> loadTotal() async {
    final cartItems = await cartService.getAll();
    double sum = 0;
    for (var item in cartItems) {
      final product = await productService.getById(item.productId);
      sum += product.price * item.quantity;
    }
    setState(() {
      total = sum;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // HEADER
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Checkout",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // STEPPER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Payment Method", style: TextStyle(color: Color(0xFF135bec), fontWeight: FontWeight.bold)),
                          Text("Step 3 of 4", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xffe5e7eb),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Container(
                            height: 8,
                            width: MediaQuery.of(context).size.width * 0.75,
                            decoration: BoxDecoration(
                              color: Color(0xFF135bec),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // SECTION TITLE
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Select Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                      SizedBox(height: 2),
                      Text("Choose your preferred payment method", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                // PAYMENT OPTIONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _paymentOption(
                        value: "card",
                        title: "Credit or Debit Card",
                        subtitle: "Visa, Mastercard, AMEX",
                        icon: Icons.credit_card,
                        color: const Color(0xFF135bec),
                        selected: selectedPayment == "card",
                        onTap: () => setState(() => selectedPayment = "card"),
                      ),
                      _paymentOption(
                        value: "bank",
                        title: "Bank Transfer",
                        subtitle: "Secure direct transfer",
                        icon: Icons.account_balance,
                        color: const Color(0xFF10b981),
                        selected: selectedPayment == "bank",
                        onTap: () => setState(() => selectedPayment = "bank"),
                      ),
                      _paymentOption(
                        value: "cod",
                        title: "Cash on Delivery",
                        subtitle: "Pay when you receive",
                        icon: Icons.payments,
                        color: const Color(0xFFf59e42),
                        selected: selectedPayment == "cod",
                        onTap: () => setState(() => selectedPayment = "cod"),
                      ),
                    ],
                  ),
                ),
                // PROMO CODE
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Promo Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 8, right: 4),
                            child: const Icon(Icons.sell, color: Colors.grey, size: 22),
                          ),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: "Enter coupon code",
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (v) => promoCode = v,
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0x1A135bec),
                              foregroundColor: const Color(0xFF135bec),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () {},
                            child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // SAVED CARDS
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Your Saved Cards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                          TextButton(
                            onPressed: () {},
                            child: const Text("+ Add New", style: TextStyle(color: Color(0xFF135bec), fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _savedCardWidget(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
            // FOOTER
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  border: const Border(top: BorderSide(color: Color(0xffe5e7eb))),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Amount", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10b981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Saving \$${saving.toStringAsFixed(2)}",
                                style: const TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF135bec),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text("Confirm & Pay", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          // Lấy userId hiện tại từ AuthService
                          int? userId = await AuthService().getCurrentUserId();
                          if (userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn cần đăng nhập để đặt hàng!')));
                            return;
                          }
                          final orderId = await orderService.checkout(
                            userId: userId,
                            addressId: widget.addressId,
                            paymentMethod: selectedPayment,
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutSuccessScreen(
                                orderId: orderId.toString(),
                                totalPaid: total,
                                paymentMethod: selectedPayment,
                              ),
                            ),
                          );
                        },
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

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF135bec) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? const Color(0xFF135bec) : Colors.grey.shade400,
                  width: 2,
                ),
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF135bec) : Colors.white,
              ),
              child: selected
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.white, size: 16),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedCardWidget() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.contactless, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Icon(Icons.credit_card, color: Colors.white54, size: 32),
            ],
          ),
          const SizedBox(height: 18),
          const Text("**** **** **** 4242", style: TextStyle(fontSize: 20, letterSpacing: 2, color: Colors.white)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Card Holder", style: TextStyle(fontSize: 10, color: Colors.white54)),
                  Text("Alex Johnson", style: TextStyle(fontSize: 14, color: Colors.white)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Expires", style: TextStyle(fontSize: 10, color: Colors.white54)),
                  Text("09/26", style: TextStyle(fontSize: 14, color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}