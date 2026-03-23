
import 'package:flutter/material.dart';
import 'dart:io';
import '../../entity/product.dart';
import '../../service/product_service.dart';
import '../../service/category_service.dart';
import '../../entity/category.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: () {
              selectedCategoryId = null;
              applyFilter();
            },
            child: _chip("All", selectedCategoryId == null),
          ),
          ...categories.map((c) => GestureDetector(
                onTap: () {
                  selectedCategoryId = c.id;
                  applyFilter();
                },
                child: _chip(c.name, selectedCategoryId == c.id),
              ))
        ],
      ),
    );
  }

  Widget _chip(String text, bool selected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text,
          style: TextStyle(color: selected ? Colors.white : Colors.black)),
    );
  }

  void applyFilter() {
    List<Product> temp = products;

    // filter theo category
    if (selectedCategoryId != null) {
      temp = temp.where((p) => p.categoryId == selectedCategoryId).toList();
    }

    // filter theo search
    if (keyword.isNotEmpty) {
      temp = temp
          .where((p) =>
              p.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredProducts = temp;
    });
  }
  // Thêm biến cho filter và search
  final productService = ProductService();
  final CategoryService categoryService = CategoryService();
  List<Product> products = [];
  List<Category> categories = [];
  // Thêm biến cho filter và search
  List<Product> filteredProducts = [];
  String keyword = "";
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  void loadAll() async {
    final cats = await categoryService.getAll();
    final prods = await productService.getAllProducts();
    setState(() {
      categories = cats;
      products = prods;
      filteredProducts = prods; // 👈 QUAN TRỌNG
    });
  }

  void loadProducts() async {
    final prods = await productService.getAllProducts();
    setState(() {
      products = prods;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text("Product Inventory"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // TODO: navigate to add product screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(),
                ),
              );

              if (result == true) {
                loadProducts(); // reload list
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildCategoryFilter(), // 👈 thêm dòng này
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // SEARCH
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (value) {
          keyword = value;
          applyFilter();
        },
        decoration: InputDecoration(
          hintText: "Search products...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // LIST PRODUCT
  Widget _buildList() {
    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final p = filteredProducts[index];
        return _productCard(p);
      },
    );
  }

  Widget _productCard(Product p) {
    Widget productImageWidget;
    if (p.image.startsWith('http')) {
      productImageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          p.image,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 70,
            height: 70,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    } else {
      productImageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(p.image),
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 70,
            height: 70,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // IMAGE
          productImageWidget,
          const SizedBox(width: 10),

          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (p.description != null && p.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      p.description!,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  categories.firstWhere((c) => c.id == p.categoryId, orElse: () => Category(id: null, name: 'Unknown')).name,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Text("\$${p.price}",
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // ACTION
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProductScreen(product: p),
                    ),
                  );
                  if (result == true) {
                    loadProducts();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _confirmDelete(p.id!);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  // Xác nhận và xóa sản phẩm
  void _confirmDelete(int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await productService.deleteProduct(productId);
      loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa sản phẩm!')),
      );
    }
  }
}