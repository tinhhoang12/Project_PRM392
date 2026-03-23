
import 'package:flutter/material.dart';
import '../../entity/product.dart';
import '../../entity/category.dart';
import '../../service/product_service.dart';
import '../../service/category_service.dart';
import '../../service/cart_service.dart';
import 'dart:io';
import '../../service/notification_service.dart';

import 'cart_screen.dart';
import 'product_category_screen.dart';
import 'product_detail_screen.dart';
import 'notification_screen.dart';
import '../../service/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Hàm helper hiển thị ảnh sản phẩm (asset, network, file)
  Widget buildProductImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
      );
    } else if (imagePath.startsWith('asset:')) {
      return Image.asset(
        imagePath.replaceFirst('asset:', ''),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
      );
    }
  }
  Widget _buildCategory() {
    if (loadingCategory) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductCategoryScreen(
                    initialCategoryName: category.name,
                  ),
                ),
              );
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
              ),
              child: Center(
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
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
  final ProductService productService = ProductService();
  final categoryService = CategoryService();
  List<Product> products = [];
  List<Category> categories = [];
  bool loadingCategory = true;
  String searchText = '';


  @override
  void initState() {
  super.initState();
  loadCategories();
  loadProducts();
  }

  void loadCategories() async {
    final data = await categoryService.getAll();
    setState(() {
      categories = data;
      loadingCategory = false;
    });
  }

  void loadProducts() async {
    final data = await productService.getAllProducts();
    setState(() {
      products = data;
    });
  }

  int unreadNotificationCount = 0;

  Future<int> fetchUnreadNotificationCount() async {
    int? userId = await AuthService().getCurrentUserId();
    if (userId == null) return 0;
    final notifications = await NotificationService.instance.getAllNotifications(userId: userId);
    return notifications.where((e) => (e['is_read'] ?? 0) == 0).length;
  }

  @override
  Widget build(BuildContext context) {
    // Lọc sản phẩm theo search
    final filteredProducts = searchText.isEmpty
        ? products
        : products.where((p) => p.name.toLowerCase().contains(searchText.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text("ShopEase"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          FutureBuilder<int>(
            future: fetchUnreadNotificationCount(),
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () async {
                      int? userId = await AuthService().getCurrentUserId();
                      if (userId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NotificationScreen(userId: userId)),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NotificationScreen(userId: 1)),
                        );
                      }
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: cartIcon(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SEARCH
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => setState(() => searchText = v),
                onSubmitted: (keyword) {
                  if (keyword.trim().isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductCategoryScreen(
                          initialKeyword: keyword.trim(),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            // BANNER
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage(
                      "https://lh3.googleusercontent.com/aida-public/AB6AXuDd_vA9LjrQG8kn-z0HvRNaN3Quqm1CMLU0BkGqFSOVO22vrR_ZyUZaDv491EOb07BbnvvvGV_ZuIypWMe8Joe7_NEC-4_HTRjtCBI82H7JwgoHxgsCKNRoaSamfkke2YgElpNcA7t5l9x38_C8OHGGvh9icsswlLpW7mHlQDwTOJ6NYW8-4FuB5PegfKd5X4ag14oP1epegxN69QSOSK3dJ3YC1Jipcii6ryFl_R12iOEpyYqX9gqrzsGXgzxVtstOjWYeuRwUehQ"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // CATEGORY
            _buildCategory(),

            const SizedBox(height: 20),

            // PRODUCT GRID
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final p = filteredProducts[index];
                  // Find the category name for this product
                  final category = categories.firstWhere(
                    (cat) => cat.id == p.categoryId,
                    orElse: () => Category(id: p.categoryId, name: 'Unknown'),
                  );

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: p),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: buildProductImage(p.image),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${p.price}',
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                    const Icon(Icons.add)
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// CATEGORY WIDGET
class CategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const CategoryItem(this.title, this.icon, {this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              child: Icon(icon),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12))
          ],
        ),
      ),
    );
  }
}