import 'package:flutter/material.dart';
import '../../service/product_service.dart';
import '../../service/category_service.dart';
import '../../entity/category.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../entity/product.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }
  File? _imageFile;
  final picker = ImagePicker();
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
    loadCategories();
  }

  void loadCategories() async {
    final data = await categoryService.getAll();
    setState(() {
      categories = data;
      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first.id;
      }
    });
  }

  void handleAdd() async {
    // Validate dữ liệu
    String? imagePath;
    if (_imageFile != null) {
      imagePath = _imageFile!.path;
    } else if (imageController.text.trim().isNotEmpty) {
      imagePath = imageController.text.trim();
    }

    if (imagePath == null || imagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh sản phẩm hoặc nhập link ảnh!')),
      );
      return;
    }
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sản phẩm!')),
      );
      return;
    }
    if (priceController.text.trim().isEmpty || double.tryParse(priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá hợp lệ!')),
      );
      return;
    }
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục!')),
      );
      return;
    }

    final product = Product(
      name: nameController.text.trim(),
      categoryId: selectedCategoryId!,
      price: double.parse(priceController.text),
      image: imagePath,
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
    );
    await productService.insertProduct(product.toMap());

    Navigator.pop(context, true); // báo về màn trước reload
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
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
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (imageController.text.trim().isNotEmpty
                        ? Image.network(imageController.text.trim(), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                        : const Icon(Icons.add_a_photo)),
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
              onPressed: handleAdd,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}