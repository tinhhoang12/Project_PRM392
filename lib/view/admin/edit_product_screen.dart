import 'package:flutter/material.dart';
import '../../entity/product.dart';
import '../../service/product_service.dart';
import '../../service/category_service.dart';
import '../../entity/category.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  File? _imageFile;
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        // Không tự động gán path local vào imageController.text nữa
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
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
    } else {
      return Image.file(File(path), fit: BoxFit.cover);
    }
  }
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final imageController = TextEditingController();
  final descriptionController = TextEditingController();

  final CategoryService categoryService = CategoryService();
  List<Category> categories = [];
  int? selectedCategoryId;

  final productService = ProductService();

  @override
  void initState() {
    super.initState();
  nameController.text = widget.product.name;
  priceController.text = widget.product.price.toString();
  imageController.text = widget.product.image;
  descriptionController.text = widget.product.description ?? '';
    loadCategories();
  }

  void loadCategories() async {
    final data = await categoryService.getAll();
    setState(() {
      categories = data;
      selectedCategoryId = widget.product.categoryId;
    });
  }

  void handleUpdate() async {
    await productService.updateProduct(widget.product.id!, {
      'name': nameController.text,
      'category_id': selectedCategoryId ?? 0,
      'price': double.tryParse(priceController.text) ?? 0,
      'image': imageController.text,
      'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
    });

    Navigator.pop(context, true); // báo về reload
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
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
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
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
              decoration: const InputDecoration(labelText: "Category"),
            ),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price")),
            TextField(controller: imageController, decoration: const InputDecoration(labelText: "Image URL")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleUpdate,
              child: const Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}