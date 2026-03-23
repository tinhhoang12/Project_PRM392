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
  String sortBy = 'name_asc';
  bool showPriceDropdown = false;
  static const double minFilterPrice = 0;
  static const double maxFilterPrice = 5000;
  RangeValues selectedPriceRange =
      const RangeValues(minFilterPrice, maxFilterPrice);

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

  void applyFilter() {
    List<Product> temp = products;

    if (selectedCategoryId != null) {
      temp = temp.where((p) => p.categoryId == selectedCategoryId).toList();
    }

    if (keyword.isNotEmpty) {
      temp = temp
          .where((p) => p.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    temp = temp
        .where(
          (p) =>
              p.price >= selectedPriceRange.start &&
              p.price <= selectedPriceRange.end,
        )
        .toList();

    switch (sortBy) {
      case 'name_desc':
        temp.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'price_asc':
        temp.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        temp.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name_asc':
      default:
        temp.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    setState(() {
      filteredProducts = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          _buildCategory(),
          _buildFilterSort(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Icon(Icons.shopping_bag),
        ],
      ),
    );
  }

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
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildFilterSort() {
    final start = selectedPriceRange.start.clamp(minFilterPrice, maxFilterPrice);
    final end = selectedPriceRange.end.clamp(minFilterPrice, maxFilterPrice);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        showPriceDropdown = !showPriceDropdown;
                      });
                    },
                    icon: const Icon(Icons.tune, size: 18),
                    label: Text(
                      'Price: \$${start.toStringAsFixed(0)} - \$${end.toStringAsFixed(0)}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: sortBy,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                      labelText: 'Sort',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'name_asc',
                        child: Text('Name A-Z'),
                      ),
                      DropdownMenuItem(
                        value: 'name_desc',
                        child: Text('Name Z-A'),
                      ),
                      DropdownMenuItem(
                        value: 'price_asc',
                        child: Text('Price low-high'),
                      ),
                      DropdownMenuItem(
                        value: 'price_desc',
                        child: Text('Price high-low'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        sortBy = value;
                      });
                      applyFilter();
                    },
                  ),
                ),
              ],
            ),
            if (showPriceDropdown) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${start.toStringAsFixed(2)} - \$${end.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RangeSlider(
                      values: RangeValues(start, end),
                      min: minFilterPrice,
                      max: maxFilterPrice,
                      divisions: 100,
                      labels: RangeLabels(
                        '\$${start.toStringAsFixed(0)}',
                        '\$${end.toStringAsFixed(0)}',
                      ),
                      onChanged: (values) {
                        setState(() {
                          selectedPriceRange = values;
                        });
                        applyFilter();
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            selectedPriceRange = const RangeValues(
                              minFilterPrice,
                              maxFilterPrice,
                            );
                          });
                          applyFilter();
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Text("No products found"),
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
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildImage(p.image),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                Text(
                  "\$${p.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

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
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
    );
  }
}
