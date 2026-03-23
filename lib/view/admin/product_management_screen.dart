import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/category.dart';
import '../../entity/product.dart';
import '../../service/category_service.dart';
import '../../service/low_stock_alert_service.dart';
import '../../service/notification_service.dart';
import '../../service/product_service.dart';
import '../../service/user_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final productService = ProductService();
  final CategoryService categoryService = CategoryService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService.instance;
  final LowStockAlertService _lowStockAlertService = LowStockAlertService();

  List<Product> products = [];
  List<Category> categories = [];
  List<Product> filteredProducts = [];
  List<Product> lowStockProducts = [];
  String keyword = '';
  int? selectedCategoryId;
  final Set<int> _alertedLowStockIds = <int>{};

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    final cats = await categoryService.getAll();
    final prods = await productService.getAllProducts();
    final lowStock = prods.where((p) => p.quantity <= 5).toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
    if (!mounted) return;
    setState(() {
      categories = cats;
      products = prods;
      filteredProducts = prods;
      lowStockProducts = lowStock;
    });

    await _maybeShowLowStockAlert(lowStock);
  }

  void applyFilter() {
    var temp = products;

    if (selectedCategoryId != null) {
      temp = temp.where((p) => p.categoryId == selectedCategoryId).toList();
    }

    if (keyword.isNotEmpty) {
      temp = temp
          .where((p) => p.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredProducts = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _search(),
            _filters(),
            if (lowStockProducts.isNotEmpty) _lowStockBanner(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                itemCount: filteredProducts.length,
                itemBuilder: (_, index) => _productCard(filteredProducts[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lowStockBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${lowStockProducts.length} low-stock product(s): ${lowStockProducts.take(3).map((e) => e.name).join(', ')}${lowStockProducts.length > 3 ? '...' : ''}',
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
          ),
          const Expanded(
            child: Text(
              'Product Inventory',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
                if (result == true) {
                  await loadAll();
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _search() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        onChanged: (value) {
          keyword = value;
          applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Search products, SKU or tags...',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    return SizedBox(
      height: 38,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _chip(
            label: 'All Products',
            active: selectedCategoryId == null,
            onTap: () {
              selectedCategoryId = null;
              applyFilter();
            },
          ),
          ...categories.map(
            (c) => _chip(
              label: c.name,
              active: selectedCategoryId == c.id,
              onTap: () {
                selectedCategoryId = c.id;
                applyFilter();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF135BEC) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF334155),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _productCard(Product p) {
    final categoryName = categories
        .firstWhere(
          (c) => c.id == p.categoryId,
          orElse: () => Category(id: null, name: 'Unknown'),
        )
        .name;

    final stockStyle = _stockStyle(p.quantity);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _productImage(p.image),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stockStyle.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stockStyle.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: stockStyle.fg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Qty: ${p.quantity} • $categoryName',
                      style:
                          const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${p.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF135BEC),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _iconBtn(Icons.inventory_2_outlined, () {}),
              const SizedBox(height: 6),
              _iconBtn(
                Icons.edit,
                () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProductScreen(product: p)),
                  );
                  if (result == true) {
                    await loadAll();
                  }
                },
              ),
              const SizedBox(height: 6),
              _iconBtn(
                Icons.delete_outline,
                () => _confirmDelete(p.id!),
                color: const Color(0xFFDC2626),
              ),
            ],
          )
        ],
      ),
    );
  }

  _StockStyle _stockStyle(int quantity) {
    if (quantity <= 0) {
      return const _StockStyle(
        label: 'Out of Stock',
        fg: Color(0xFFB91C1C),
        bg: Color(0xFFFEE2E2),
      );
    }
    if (quantity <= 5) {
      return const _StockStyle(
        label: 'Low Stock',
        fg: Color(0xFFB45309),
        bg: Color(0xFFFEF3C7),
      );
    }
    return const _StockStyle(
      label: 'In Stock',
      fg: Color(0xFF166534),
      bg: Color(0xFFDCFCE7),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color ?? const Color(0xFF64748B)),
      ),
    );
  }

  Widget _productImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _productImage(''),
      );
    }

    if (path.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
      );
    }

    return Image.file(
      File(path),
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _productImage(''),
    );
  }

  Future<void> _confirmDelete(int productId) async {
    Product? product;
    for (final p in products) {
      if (p.id == productId) {
        product = p;
        break;
      }
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await productService.deleteProduct(productId);
      if (product != null) {
        await _notifyAdminIfStaffDeleted(product);
      }
      await loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted.')),
      );
    }
  }

  Future<void> _notifyAdminIfStaffDeleted(Product product) async {
    final actor = await _userService.getCurrentUser();
    if (actor == null || actor.role != 'staff') return;

    final actorName = (actor.fullName?.trim().isNotEmpty ?? false)
        ? actor.fullName!.trim()
        : actor.username;

    await _notificationService.addNotificationToRole(
      role: 'admin',
      title: 'Staff deleted product',
      body:
          '$actorName deleted product #${product.id}: ${product.name}. Last price: \$${product.price.toStringAsFixed(2)}, Last qty: ${product.quantity}.',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _maybeShowLowStockAlert(List<Product> lowStockProducts) async {
    await _lowStockAlertService.clearMutedForResolvedProducts();

    final currentLowIds = lowStockProducts.map((p) => p.id).whereType<int>().toSet();
    _alertedLowStockIds.removeWhere((id) => !currentLowIds.contains(id));

    if (currentLowIds.isEmpty || !mounted) return;

    final mutedIds = await _lowStockAlertService.getMutedProductIds(currentLowIds);
    final candidates = lowStockProducts.where((p) {
      final id = p.id;
      if (id == null) return false;
      return !mutedIds.contains(id) && !_alertedLowStockIds.contains(id);
    }).toList();

    if (candidates.isEmpty || !mounted) return;

    final muteThisBatch = await _showLowStockDialog(candidates);
    final candidateIds = candidates.map((p) => p.id).whereType<int>().toSet();
    _alertedLowStockIds.addAll(candidateIds);
    if (muteThisBatch) {
      await _lowStockAlertService.muteProducts(candidateIds);
    }
  }

  Future<bool> _showLowStockDialog(List<Product> items) async {
    bool dontShowAgain = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Low Stock Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${items.length} product(s) have quantity at or below 5.'),
              const SizedBox(height: 10),
              ...items.take(5).map(
                    (p) => Text('- ${p.name} (Qty: ${p.quantity})'),
                  ),
              CheckboxListTile(
                value: dontShowAgain,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Do not show again for these products',
                  style: TextStyle(fontSize: 13),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  setLocalState(() {
                    dontShowAgain = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, dontShowAgain),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }
}

class _StockStyle {
  const _StockStyle({
    required this.label,
    required this.fg,
    required this.bg,
  });

  final String label;
  final Color fg;
  final Color bg;
}
