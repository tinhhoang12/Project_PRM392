import 'package:flutter/material.dart';
import 'dart:io';

import '../../entity/category.dart';
import '../../entity/product.dart';
import '../../service/auth_service.dart';
import '../../service/cart_service.dart';
import '../../service/category_service.dart';
import '../../service/notification_service.dart';
import '../../service/product_service.dart';
import '../login_screen.dart';
import 'cart_screen.dart';
import 'notification_screen.dart';
import 'product_category_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService productService = ProductService();
  final categoryService = CategoryService();

  List<Product> products = [];
  List<Category> categories = [];
  bool loadingCategory = true;
  String searchText = '';

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
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
    );
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
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
              ),
              child: Center(
                child: Icon(
                  _categoryIcon(category.name),
                  size: 30,
                  color: const Color(0xFF135BEC),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final key = name.trim().toLowerCase();
    if (key.contains('audio')) return Icons.headphones;
    if (key.contains('wear')) return Icons.watch;
    if (key.contains('comput')) return Icons.laptop_mac;
    if (key.contains('gaming') || key.contains('game')) return Icons.sports_esports;
    return Icons.category;
  }

  Widget cartIcon() {
    return FutureBuilder(
      future: CartService.instance.getAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _iconWithBadge(icon: Icons.shopping_cart, count: 0);
        }
        final count = (snapshot.data as List)
            .fold<int>(0, (int sum, item) => sum + (item.quantity as int));
        return _iconWithBadge(icon: Icons.shopping_cart, count: count);
      },
    );
  }

  Widget _iconWithBadge({required IconData icon, required int count}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(icon, size: 24),
          ),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

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

  Future<int> fetchUnreadNotificationCount() async {
    final userId = await AuthService().getCurrentUserId();
    if (userId == null) return 0;
    final notifications =
        await NotificationService.instance.getAllNotifications(userId: userId);
    return notifications.where((e) => (e['is_read'] ?? 0) == 0).length;
  }

  Future<void> _showLoginRequiredDialog() async {
    final shouldGo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to login to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Go to login'),
          ),
        ],
      ),
    );

    if (shouldGo == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = searchText.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(searchText.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text('ShopEase'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          FutureBuilder<int>(
            future: fetchUnreadNotificationCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return IconButton(
                icon: _iconWithBadge(icon: Icons.notifications, count: count),
                onPressed: () async {
                  final userId = await AuthService().getCurrentUserId();
                  if (userId != null) {
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NotificationScreen(userId: userId)),
                    );
                    return;
                  }

                  if (!context.mounted) return;
                  await _showLoginRequiredDialog();
                },
              );
            },
          ),
          IconButton(
            icon: cartIcon(),
            onPressed: () async {
              final userId = await AuthService().getCurrentUserId();
              if (userId == null) {
                if (!context.mounted) return;
                await _showLoginRequiredDialog();
                return;
              }
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
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
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDd_vA9LjrQG8kn-z0HvRNaN3Quqm1CMLU0BkGqFSOVO22vrR_ZyUZaDv491EOb07BbnvvvGV_ZuIypWMe8Joe7_NEC-4_HTRjtCBI82H7JwgoHxgsCKNRoaSamfkke2YgElpNcA7t5l9x38_C8OHGGvh9icsswlLpW7mHlQDwTOJ6NYW8-4FuB5PegfKd5X4ag14oP1epegxN69QSOSK3dJ3YC1Jipcii6ryFl_R12iOEpyYqX9gqrzsGXgzxVtstOjWYeuRwUehQ'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCategory(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final p = filteredProducts[index];
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
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${p.price.toStringAsFixed(2)}',
                                      style:
                                          const TextStyle(color: Colors.blue),
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
