import 'package:flutter/material.dart';
import '../../service/cart_service.dart';
import '../../entity/cart_item.dart';
import '../../entity/product.dart';
import 'dart:io';
import '../../service/product_service.dart';
// Removed unused imports
import 'checkout_address_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final cart = CartService.instance;
  List<CartItem> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() { loading = true; });
    items = await cart.getAll();
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping Cart"),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text("Cart is empty"))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return FutureBuilder<Product>(
                            future: ProductService().getById(items[index].productId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const ListTile(title: Text("Loading..."));
                              }
                              return _item(items[index], snapshot.data!);
                            },
                          );
                        },
                      ),
          ),
          _bottom()
        ],
      ),
    );
  }

  Widget _item(CartItem item, Product product) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          (product.image.startsWith('http')
              ? Image.network(
                  product.image,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                )
              : Image.file(
                  File(product.image),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                )),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("\$${product.price}"),
              ],
            ),
          ),

          // quantity
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  await cart.decrease(product.id!);
                  _loadCart();
                },
                icon: const Icon(Icons.remove),
              ),
              Text(item.quantity.toString()),
              IconButton(
                onPressed: () async {
                  await cart.increase(product.id!);
                  _loadCart();
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          // delete
          IconButton(
            onPressed: () async {
              await cart.delete(product.id!);
              _loadCart();
            },
            icon: const Icon(Icons.delete, color: Colors.red),
          )
        ],
      ),
    );
  }

  Widget _bottom() {
  //
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 5, color: Colors.black12)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              FutureBuilder<double>(
                future: _calculateTotal(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text("...");
                  return Text("\$${snapshot.data!.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: items.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutAddressScreen(),
                      ),
                    );
                  },
            child: const Text("Checkout"),
          )
        ],
      ),
    );
  }

  Future<double> _calculateTotal() async {
    double total = 0;
    for (final item in items) {
      final product = await ProductService().getById(item.productId);
      total += product.price * item.quantity;
    }
    return total;
  }
}