import 'package:flutter/material.dart';
import '../../entity/product.dart';
import '../../service/cart_service.dart';
import 'dart:io';

import '../../service/auth_service.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Widget cartIcon() {
    return Stack(
      children: [
        const Icon(Icons.shopping_cart),
        Positioned(
          right: 0,
          top: 0,
          child: FutureBuilder(
            future: CartService.instance.getAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              int count = ((snapshot.data as List)
                      .fold<int>(0, (int sum, item) => sum + (item.quantity as int)));
              if (count == 0) return const SizedBox();
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10),
                ),
              );
            },
          ),
        )
      ],
    );
  }
  bool isPressed = false;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      // ===== HEADER =====
      appBar: AppBar(
        title: const Text("Product Detail"),
        centerTitle: true,
        actions: const [
          Icon(Icons.favorite_border),
          SizedBox(width: 12),
          Icon(Icons.share),
          SizedBox(width: 12),
        ],
      ),

      // ===== BODY =====
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // IMAGE
                  Container(
                    height: 300,
                    width: double.infinity,
                    child: (p.image.startsWith('http')
                        ? Image.network(
                            p.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
                          )
                        : Image.file(
                            File(p.image),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
                          )),
                  ),

                  const SizedBox(height: 16),

                  // INFO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Icon(Icons.star_half, color: Colors.amber, size: 16),
                            SizedBox(width: 8),
                            Text("4.8 (1.2k Reviews)"),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "\$${p.price}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // STOCK + QUANTITY
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text("In Stock"),
                                ],
                              ),

                              // QUANTITY
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() {
                                          quantity--;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(
                                    quantity.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        quantity++;
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // DESCRIPTION
                        const Text(
                          "Description",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          p.description?.isNotEmpty == true
                              ? p.description!
                              : "No description.",
                          style: const TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===== BOTTOM BAR =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                // CART ICON
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: cartIcon(),
                  ),
                ),

                const SizedBox(width: 12),

                // ADD TO CART
                Expanded(
                  child: AnimatedScale(
                    scale: isPressed ? 0.9 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        setState(() => isPressed = true);
                        // Lấy userId hiện tại từ AuthService
                        int? userId = await AuthService().getCurrentUserId();
                        await CartService.instance.add(
                          widget.product.id!,
                          widget.product.price,
                          quantity: quantity,
                          userId: userId,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Added to cart")),
                        );
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) setState(() => isPressed = false);
                        });
                      },
                      child: const Text("Add to Cart"),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}