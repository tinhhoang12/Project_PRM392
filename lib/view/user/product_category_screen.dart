import 'dart:io';
import 'package:flutter/material.dart';
import '../../entity/product.dart';
import '../../entity/category.dart';
import '../../service/product_service.dart';
import '../../service/category_service.dart';
import 'product_detail_screen.dart';



class ProductCategoryScreen extends StatefulWidget {
  final String? initialCategoryName;
  final String? initialKeyword;
  const ProductCategoryScreen({this.initialCategoryName, this.initialKeyword, Key? key}) : super(key: key);

  @override
  State<ProductCategoryScreen> createState() => _ProductCategoryScreenState();
}


class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
  final productService = ProductService();
  final categoryService = CategoryService();

  final searchController = TextEditingController();

  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Category> categories = [];

  String keyword = "";
  int? selectedCategoryId;


  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      keyword = widget.initialKeyword!;
      searchController.text = widget.initialKeyword!;
    }
    loadData();
  }


  void loadData() async {
    final prods = await productService.getAllProducts();
    final cats = await categoryService.getAll();

    setState(() {
      products = prods;
      categories = cats;
    });

    // 🔥 xử lý filter sau khi load xong
    if (widget.initialCategoryName != null) {
      final match = cats.firstWhere(
        (c) => c.name == widget.initialCategoryName,
        orElse: () => Category(id: null, name: ''),
      );
      if (match.id != null) {
        selectedCategoryId = match.id;
      }
    }

    if (widget.initialKeyword != null) {
      keyword = widget.initialKeyword!;
      searchController.text = keyword;
    }

    applyFilter();
  }

  // ================= FILTER =================
  void applyFilter() {
    List<Product> temp = products;

    if (selectedCategoryId != null) {
      temp =
          temp.where((p) => p.categoryId == selectedCategoryId).toList();
    }

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

  // ================= UI =================


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          _buildCategory(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Smart Electronics",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Icon(Icons.shopping_bag),
        ],
      ),
    );
  }

  // SEARCH
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          keyword = value;
          applyFilter();
        },
        decoration: InputDecoration(
          hintText: "Search product...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: keyword.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    keyword = "";
                    applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // CATEGORY
  Widget _buildCategory() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip("All", selectedCategoryId == null, () {
            selectedCategoryId = null;
            applyFilter();
          }),
          ...categories.map((c) => _chip(
                c.name,
                selectedCategoryId == c.id,
                () {
                  selectedCategoryId = c.id;
                  applyFilter();
                },
              ))
        ],
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
              color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  // GRID PRODUCT
  Widget _buildGrid() {
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text("No products found 😢"),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final p = filteredProducts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            );
          },
          child: _productCard(p),
        );
      },
    );
  }

  Widget _productCard(Product p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // IMAGE
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildImage(p.image),
            ),
          ),

          // INFO
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 4),

                Text(
                  categories
                      .firstWhere(
                        (c) => c.id == p.categoryId,
                        orElse: () => Category(id: null, name: 'Unknown'),
                      )
                      .name,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 4),

                Text("\$${p.price}",
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // LOAD IMAGE (LOCAL + NETWORK)
  Widget _buildImage(String path) {
    if (path.trim().isEmpty) {
      return const Icon(Icons.add_a_photo);
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }
  }
}