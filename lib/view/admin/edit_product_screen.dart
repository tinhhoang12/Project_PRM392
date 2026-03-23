import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../entity/category.dart';
import '../../entity/product.dart';
import '../../service/category_service.dart';
import '../../service/notification_service.dart';
import '../../service/product_service.dart';
import '../../service/user_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  File? _imageFile;
  final picker = ImagePicker();

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final imageController = TextEditingController();
  final descriptionController = TextEditingController();

  final CategoryService categoryService = CategoryService();
  final productService = ProductService();
  final UserService _userService = UserService();
  final NotificationService _notificationService = NotificationService.instance;

  List<Category> categories = [];
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.product.name;
    priceController.text = widget.product.price.toString();
    quantityController.text = widget.product.quantity.toString();
    imageController.text = widget.product.image;
    descriptionController.text = widget.product.description ?? '';
    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await categoryService.getAll();
    if (!mounted) return;
    setState(() {
      categories = data;
      selectedCategoryId = widget.product.categoryId;
    });
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Widget buildImage() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
    final path = imageController.text.trim();
    if (path.isEmpty) {
      return const Icon(Icons.add_a_photo);
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }

  Future<void> handleUpdate() async {
    final quantity = int.tryParse(quantityController.text.trim());
    if (quantity == null || quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity.')),
      );
      return;
    }

    final imagePath = _imageFile != null ? _imageFile!.path : imageController.text.trim();
    final newPrice = double.tryParse(priceController.text) ?? 0;
    final productId = widget.product.id;
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid product id.')),
      );
      return;
    }

    await productService.updateProduct(productId, {
      'name': nameController.text,
      'category_id': selectedCategoryId ?? 0,
      'price': newPrice,
      'quantity': quantity,
      'image': imagePath,
      'description': descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
    });

    await _notifyAdminIfStaffUpdated(
      productId: productId,
      oldName: widget.product.name,
      newName: nameController.text.trim(),
      oldPrice: widget.product.price,
      newPrice: newPrice,
      oldQty: widget.product.quantity,
      newQty: quantity,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _notifyAdminIfStaffUpdated({
    required int productId,
    required String oldName,
    required String newName,
    required double oldPrice,
    required double newPrice,
    required int oldQty,
    required int newQty,
  }) async {
    final actor = await _userService.getCurrentUser();
    if (actor == null || actor.role != 'staff') return;

    final actorName = (actor.fullName?.trim().isNotEmpty ?? false)
        ? actor.fullName!.trim()
        : actor.username;

    await _notificationService.addNotificationToRole(
      role: 'admin',
      title: 'Staff updated product',
      body:
          '$actorName updated product #$productId.\nName: $oldName -> $newName\nPrice: \$${oldPrice.toStringAsFixed(2)} -> \$${newPrice.toStringAsFixed(2)}\nQty: $oldQty -> $newQty',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: buildImage(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButtonFormField<int>(
              value: selectedCategoryId,
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategoryId = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleUpdate,
              child: const Text('Update'),
            )
          ],
        ),
      ),
    );
  }
}
