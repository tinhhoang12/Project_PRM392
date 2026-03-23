import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../entity/category.dart';
import '../../entity/product.dart';
import '../../service/category_service.dart';
import '../../service/notification_service.dart';
import '../../service/product_service.dart';
import '../../service/user_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final picker = ImagePicker();
  File? _imageFile;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController(text: '0');
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
    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await categoryService.getAll();
    if (!mounted) return;
    setState(() {
      categories = data;
      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first.id;
      }
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

  Future<void> handleAdd() async {
    String? imagePath;
    if (_imageFile != null) {
      imagePath = _imageFile!.path;
    } else if (imageController.text.trim().isNotEmpty) {
      imagePath = imageController.text.trim();
    }

    if (imagePath == null || imagePath.isEmpty) {
      _show('Please choose an image or enter image URL.');
      return;
    }
    if (nameController.text.trim().isEmpty) {
      _show('Please enter product name.');
      return;
    }
    if (priceController.text.trim().isEmpty ||
        double.tryParse(priceController.text) == null) {
      _show('Please enter valid price.');
      return;
    }
    if (selectedCategoryId == null) {
      _show('Please choose category.');
      return;
    }
    final quantity = int.tryParse(quantityController.text.trim());
    if (quantityController.text.trim().isEmpty || quantity == null || quantity < 0) {
      _show('Please enter valid quantity.');
      return;
    }

    final product = Product(
      name: nameController.text.trim(),
      categoryId: selectedCategoryId!,
      price: double.parse(priceController.text),
      quantity: quantity,
      image: imagePath,
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
    );
    final productId = await productService.insertProduct(product.toMap());
    await _notifyAdminIfStaffCreated(product, productId);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _notifyAdminIfStaffCreated(Product product, int productId) async {
    final actor = await _userService.getCurrentUser();
    if (actor == null || actor.role != 'staff') return;

    final actorName = (actor.fullName?.trim().isNotEmpty ?? false)
        ? actor.fullName!.trim()
        : actor.username;

    await _notificationService.addNotificationToRole(
      role: 'admin',
      title: 'Staff created product',
      body:
          '$actorName created product #$productId: ${product.name}. Price: \$${product.price.toStringAsFixed(2)}, Qty: ${product.quantity}.',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text('Add Product'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _imagePickerCard(),
          const SizedBox(height: 14),
          _formCard(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: handleAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135BEC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Save Product',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _imagePickerCard() {
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
            'Product Image',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : (imageController.text.trim().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageController.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImage(),
                          ),
                        )
                      : _placeholderImage()),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: imageController,
            decoration: InputDecoration(
              labelText: 'Image URL (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 40, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text('Tap to pick image', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: _input('Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: _input('Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: selectedCategoryId,
            decoration: _input('Category'),
            items: categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedCategoryId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _input('Price'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: _input('Quantity'),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
