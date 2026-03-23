import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/product.dart';
import '../../service/auth_service.dart';
import '../../service/inventory_service.dart';
import '../../service/low_stock_alert_service.dart';
import '../../service/product_service.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final productService = ProductService();
  final inventoryService = InventoryService();
  final authService = AuthService();
  final LowStockAlertService _lowStockAlertService = LowStockAlertService();

  List<Product> products = [];
  bool loading = true;
  final Set<int> _alertedLowStockIds = <int>{};

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final data = await productService.getAllProducts();
    if (!mounted) return;

    setState(() {
      products = data;
      loading = false;
    });

    final lowStockProducts = data.where((p) => p.quantity <= 5).toList();
    await _maybeShowLowStockAlert(lowStockProducts);
  }

  Future<void> _changeQuantity(Product p, int delta) async {
    final actorUserId = await authService.getCurrentUserId();
    if (actorUserId == null) return;

    final next = (p.quantity + delta).clamp(0, 999999);
    final updated = await inventoryService.updateStock(
      productId: p.id!,
      newQuantity: next,
      actorUserId: actorUserId,
    );

    await loadProducts();
    if (!mounted) return;
    _showUpdateAlert(p.name, p.quantity, updated.quantity);
    if (updated.quantity <= 5) {
      _showLowStockSnack(updated.name, updated.quantity);
    }
  }

  Future<void> _setQuantity(Product p) async {
    final controller = TextEditingController(text: p.quantity.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Update Quantity - ${p.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final q = int.tryParse(controller.text.trim());
              if (q == null || q < 0) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, q);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final actorUserId = await authService.getCurrentUserId();
    if (actorUserId == null) return;

    final updated = await inventoryService.updateStock(
      productId: p.id!,
      newQuantity: result,
      actorUserId: actorUserId,
    );

    await loadProducts();
    if (!mounted) return;
    _showUpdateAlert(p.name, p.quantity, updated.quantity);
    if (updated.quantity <= 5) {
      _showLowStockSnack(updated.name, updated.quantity);
    }
  }

  void _showUpdateAlert(String productName, int oldQty, int newQty) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Stock Updated'),
        content: Text(
          '$productName: quantity updated from $oldQty to $newQty. Audit log recorded.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLowStockSnack(String productName, int quantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Low stock warning: $productName (qty: $quantity)'),
        backgroundColor: const Color(0xFFB45309),
      ),
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
              Text('There are ${items.length} product(s) with quantity at or below 5.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text('Inventory Management'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (_, index) => _item(products[index]),
            ),
    );
  }

  Widget _item(Product p) {
    final isLow = p.quantity <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _image(p.image),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Qty: ${p.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    if (isLow)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'LOW STOCK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeQuantity(p, -1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            onPressed: () => _changeQuantity(p, 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            onPressed: () => _setQuantity(p),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  Widget _image(String image) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _image(''),
      );
    }
    if (image.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
      );
    }
    return Image.file(
      File(image),
      width: 56,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _image(''),
    );
  }
}
