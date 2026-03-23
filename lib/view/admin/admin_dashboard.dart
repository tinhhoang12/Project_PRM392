import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../service/admin_service.dart';
import '../../service/low_stock_alert_service.dart';
import '../../service/notification_service.dart';
import '../../service/user_service.dart';
import 'admin_notification_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final service = AdminService();
  final NotificationService _notificationService = NotificationService.instance;
  final UserService _userService = UserService();
  final LowStockAlertService _lowStockAlertService = LowStockAlertService();

  double revenue = 0;
  int orders = 0;
  int products = 0;
  int lowStockCount = 0;
  int unreadNotificationCount = 0;
  int? _currentUserId;

  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> salesStats = [];
  List<Map<String, dynamic>> lowStockProducts = [];
  final Set<int> _alertedLowStockIds = <int>{};

  @override
  void initState() {
    super.initState();
    loadData();
    _loadNotificationCount();
  }

  Future<void> loadData() async {
    final r = await service.getTodayRevenue();
    final o = await service.getTotalOrders();
    final p = await service.getTotalProducts();
    final low = await service.getLowStockCount();
    final recent = await service.getRecentOrders();
    final sales = await service.getRevenueLastNDays(days: 7);
    final lowStockList = await service.getLowStockProducts(limit: 5);

    if (!mounted) return;
    setState(() {
      revenue = r;
      orders = o;
      products = p;
      lowStockCount = low;
      recentOrders = recent;
      salesStats = sales;
      lowStockProducts = lowStockList;
    });

    await _maybeShowLowStockAlert(lowStockList);
  }

  Future<void> _loadNotificationCount() async {
    final user = await _userService.getCurrentUser();
    if (user?.id == null || !mounted) return;
    final unread =
        await _notificationService.getUnreadCount(userId: user!.id!);
    if (!mounted) return;
    setState(() {
      _currentUserId = user.id;
      unreadNotificationCount = unread;
    });
  }

  Future<void> _openNotifications() async {
    if (_currentUserId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminNotificationScreen(userId: _currentUserId!),
      ),
    );
    await _loadNotificationCount();
  }

  Future<void> _maybeShowLowStockAlert(List<Map<String, dynamic>> lowStockList) async {
    await _lowStockAlertService.clearMutedForResolvedProducts();

    final currentLowIds = lowStockList
        .map((e) => (e['id'] as int?))
        .whereType<int>()
        .toSet();

    _alertedLowStockIds.removeWhere((id) => !currentLowIds.contains(id));

    if (currentLowIds.isEmpty || !mounted) return;

    final mutedIds = await _lowStockAlertService.getMutedProductIds(currentLowIds);
    final candidates = lowStockList.where((item) {
      final id = item['id'] as int?;
      if (id == null) return false;
      return !mutedIds.contains(id) && !_alertedLowStockIds.contains(id);
    }).toList();

    if (candidates.isEmpty || !mounted) return;

    final muteThisBatch = await _showLowStockDialog(candidates);
    final candidateIds = candidates
        .map((e) => e['id'] as int?)
        .whereType<int>()
        .toSet();
    _alertedLowStockIds.addAll(candidateIds);

    if (muteThisBatch) {
      await _lowStockAlertService.muteProducts(candidateIds);
    }
  }

  Future<bool> _showLowStockDialog(List<Map<String, dynamic>> items) async {
    bool dontShowAgain = false;
    final count = items.length;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Low Stock Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count product(s) are below quantity 5.'),
              const SizedBox(height: 10),
              ...items.take(5).map(
                    (e) => Text(
                      '- ${e['name'] ?? 'Product #${e['id']}'} (Qty: ${e['quantity'] ?? 0})',
                    ),
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
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsGrid(),
                  const SizedBox(height: 14),
                  _buildChartCard(),
                  if (lowStockProducts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildLowStockCard(),
                  ],
                  const SizedBox(height: 16),
                  _buildRecentOrders(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF135BEC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dashboard, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Welcome back, Admin',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openNotifications,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_none,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (unreadNotificationCount > 0)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          unreadNotificationCount > 99
                              ? '99+'
                              : '$unreadNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _metricCard(
          icon: Icons.payments,
          title: "Today's Revenue",
          value: '\$${revenue.toStringAsFixed(2)}',
          trend: '+12.5%',
          trendColor: const Color(0xFF059669),
          trendBg: const Color(0xFFECFDF3),
        ),
        _metricCard(
          icon: Icons.shopping_bag,
          title: 'Total Orders',
          value: '$orders',
          trend: '+8.2%',
          trendColor: const Color(0xFF059669),
          trendBg: const Color(0xFFECFDF3),
        ),
        _metricCard(
          icon: Icons.inventory_2,
          title: 'Active Products',
          value: '$products',
          trend: '+0.5%',
          trendColor: const Color(0xFF64748B),
          trendBg: const Color(0xFFF1F5F9),
        ),
        _metricCard(
          icon: Icons.warning_amber_rounded,
          title: 'Low Stock',
          value: '$lowStockCount',
          trend: lowStockCount > 0 ? 'Needs action' : 'Healthy',
          trendColor:
              lowStockCount > 0 ? const Color(0xFFB45309) : const Color(0xFF059669),
          trendBg:
              lowStockCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF3),
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
    required Color trendBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFF135BEC), size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: trendColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final values = salesStats
        .map((e) => (e['revenue'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final labels = salesStats
        .map((e) => _weekdayLabel(e['day']?.toString()))
        .toList();
    final total = values.fold<double>(0, (sum, v) => sum + v);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales Statistics',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Last 7 Days',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: Color(0xFF135BEC)),
              SizedBox(width: 6),
              Text(
                'Revenue trend',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
              child: CustomPaint(
              painter: _SimpleLineChartPainter(values: values),
              child: Container(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((label) => Expanded(
                      child: Text(
                        label,
                        style: _dayStyle,
                        textAlign: TextAlign.center,
                      ),
                    ))
                .toList(),
          )
        ],
      ),
    );
  }

  String _weekdayLabel(String? dayIso) {
    final dt = DateTime.tryParse(dayIso ?? '');
    if (dt == null) return '---';
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[dt.weekday - 1];
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF135BEC),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        ...recentOrders.map(_recentOrderItem),
      ],
    );
  }

  Widget _buildLowStockCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C)),
              SizedBox(width: 8),
              Text(
                'Low Stock Products',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lowStockProducts.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      p['name']?.toString() ?? 'Product #${p['id']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Qty: ${(p['quantity'] as num?)?.toInt() ?? 0}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _recentOrderItem(Map<String, dynamic> order) {
    final image = order['product_image']?.toString();
    final status = (order['status']?.toString() ?? 'Pending').toLowerCase();
    final statusColor = status == 'delivered' || status == 'paid'
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildOrderImage(image),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['product_name']?.toString() ?? 'Order #${order['id']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '#ORD-${order['id']} • ${_timeText(order['created_at']?.toString())}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${((order['total'] as num?) ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                _labelStatus(order['status']?.toString()),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOrderImage(String? image) {
    if (image == null || image.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.image, color: Color(0xFF94A3B8), size: 20),
      );
    }

    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildOrderImage(null),
      );
    }

    return Image.file(
      File(image),
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildOrderImage(null),
    );
  }

  String _labelStatus(String? status) {
    if (status == null) return 'Pending';
    if (status == 'Delivered') return 'Paid';
    return status;
  }

  String _timeText(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return 'just now';

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${math.max(1, diff.inDays)} days ago';
  }
}

const _dayStyle = TextStyle(
  fontSize: 10,
  color: Color(0xFF94A3B8),
  fontWeight: FontWeight.bold,
);

class _SimpleLineChartPainter extends CustomPainter {
  _SimpleLineChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final normalized = values.length < 2
        ? [0.0, 0.0]
        : values;
    final maxValue = normalized.reduce(math.max);
    final minValue = normalized.reduce(math.min);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final points = <Offset>[];
    for (var i = 0; i < normalized.length; i++) {
      final x = (i / (normalized.length - 1)) * size.width;
      final yRatio = (normalized[i] - minValue) / range;
      final y = size.height - (yRatio * size.height * 0.85) - (size.height * 0.05);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x2A135BEC), Color(0x00135BEC)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF135BEC)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SimpleLineChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
