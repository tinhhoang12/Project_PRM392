import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/product.dart';
import '../../service/auth_service.dart';
import '../../service/cart_service.dart';
import '../../service/review_service.dart';
import '../login_screen.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _reviewService = ReviewService();
  final _commentController = TextEditingController();

  bool isPressed = false;
  int quantity = 1;
  int _selectedRating = 5;
  bool _loadingReviews = true;
  bool _submittingReview = false;

  double _avgRating = 0;
  int _ratingCount = 0;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final productId = widget.product.id;
    if (productId == null) return;

    final summary = await _reviewService.getRatingSummary(productId);
    final reviews = await _reviewService.getReviewsByProduct(productId);

    if (!mounted) return;
    setState(() {
      _avgRating = (summary['avg_rating'] as num?)?.toDouble() ?? 0;
      _ratingCount = (summary['total_reviews'] as int?) ?? 0;
      _reviews = reviews;
      _loadingReviews = false;
    });
  }

  Future<void> _submitReview() async {
    final productId = widget.product.id;
    if (productId == null) return;

    final userId = await AuthService().getCurrentUserId();
    if (userId == null) {
      if (!mounted) return;
      await _showLoginRequiredDialog();
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your comment.')),
      );
      return;
    }

    setState(() {
      _submittingReview = true;
    });

    try {
      await _reviewService.upsertReview(
        productId: productId,
        userId: userId,
        rating: _selectedRating,
        comment: comment,
      );
      _commentController.clear();
      await _loadReviews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _submittingReview = false;
      });
    }
  }

  Widget cartIcon() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        const Center(child: Icon(Icons.shopping_cart)),
        Positioned(
          right: -2,
          top: -2,
          child: FutureBuilder(
            future: CartService.instance.getAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final count = (snapshot.data as List)
                  .fold<int>(0, (int sum, item) => sum + (item.quantity as int));
              if (count == 0) return const SizedBox();
              return Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              );
            },
          ),
        )
      ],
    );
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
    final p = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text('Product Detail'),
        centerTitle: true,
        actions: const [
          Icon(Icons.favorite_border),
          SizedBox(width: 12),
          Icon(Icons.share),
          SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: (p.image.startsWith('http')
                        ? Image.network(
                            p.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 80),
                          )
                        : Image.file(
                            File(p.image),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 80),
                          )),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ..._buildStaticStars(_avgRating),
                            const SizedBox(width: 8),
                            Text(
                              '${_avgRating.toStringAsFixed(1)} (${_ratingCount} reviews)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\$${p.price}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('In Stock'),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() {
                                          quantity--;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(
                                    quantity.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        quantity++;
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Description',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.description?.isNotEmpty == true
                              ? p.description!
                              : 'No description.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 22),
                        _reviewComposer(),
                        const SizedBox(height: 14),
                        _reviewList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: cartIcon()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedScale(
                    scale: isPressed ? 0.9 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        setState(() => isPressed = true);

                        final userId = await AuthService().getCurrentUserId();
                        if (userId == null) {
                          if (!mounted) return;
                          await _showLoginRequiredDialog();
                          setState(() => isPressed = false);
                          return;
                        }

                        try {
                          await CartService.instance.add(
                            widget.product.id!,
                            widget.product.price,
                            quantity: quantity,
                            userId: userId,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                          setState(() => isPressed = false);
                          return;
                        }

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (mounted) setState(() => isPressed = false);
                        });
                      },
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _reviewComposer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a review',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;
              final active = _selectedRating >= star;
              return IconButton(
                onPressed: () {
                  setState(() {
                    _selectedRating = star;
                  });
                },
                icon: Icon(
                  active ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your experience with this product...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _submittingReview ? null : _submitReview,
              child: _submittingReview
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: _loadingReviews
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No reviews yet.')),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Reviews (${_reviews.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._reviews.map(_reviewItem),
                  ],
                ),
    );
  }

  Widget _reviewItem(Map<String, dynamic> review) {
    final name = review['reviewer_name']?.toString() ?? 'User';
    final comment = review['comment']?.toString() ?? '';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final createdAt = review['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                _formatDate(createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star : Icons.star_border,
                size: 16,
                color: Colors.amber,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(comment),
        ],
      ),
    );
  }

  List<Widget> _buildStaticStars(double value) {
    final full = value.floor();
    final hasHalf = (value - full) >= 0.5;
    return List.generate(5, (index) {
      if (index < full) {
        return const Icon(Icons.star, color: Colors.amber, size: 16);
      }
      if (index == full && hasHalf) {
        return const Icon(Icons.star_half, color: Colors.amber, size: 16);
      }
      return const Icon(Icons.star_border, color: Colors.amber, size: 16);
    });
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
