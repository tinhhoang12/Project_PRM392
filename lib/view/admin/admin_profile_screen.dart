import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/order.dart';
import '../../entity/user.dart';
import '../../service/auth_service.dart';
import '../../service/order_service.dart';
import '../../service/user_service.dart';
import '../login_screen.dart';
import 'edit_user_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  final User user;

  const AdminProfileScreen({super.key, required this.user});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final orderService = OrderService();
  final userService = UserService();

  User? currentUser;
  bool loadingUser = true;
  bool loadingTransactions = true;
  List<Order> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTransactions();
  }

  Future<void> _loadUser() async {
    final userId = widget.user.id;
    if (userId == null) {
      setState(() {
        currentUser = widget.user;
        loadingUser = false;
      });
      return;
    }

    final dbUser = await userService.getUserById(userId);
    if (!mounted) return;
    setState(() {
      currentUser = dbUser ?? widget.user;
      loadingUser = false;
    });
  }

  Future<void> _loadTransactions() async {
    final orders = await orderService.getOrders();
    if (!mounted) return;
    setState(() {
      transactions = orders.take(5).toList();
      loadingTransactions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser ?? widget.user;

    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: SafeArea(
        child: loadingUser
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  _header(),
                  _hero(user),
                  _contact(user),
                  _transaction(),
                  _logout(),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
          const Expanded(
            child: Text(
              'User Profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
    );
  }

  Widget _hero(User user) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        children: [
          CircleAvatar(
            radius: 64,
            backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                ? (user.avatar!.startsWith('http')
                    ? NetworkImage(user.avatar!)
                    : FileImage(File(user.avatar!)) as ImageProvider)
                : const NetworkImage('https://i.pravatar.cc/300'),
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName ?? 'No Name',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            user.role == 'admin' ? 'Senior Operations Manager' : 'Staff',
            style: const TextStyle(
              color: Color(0xFF135BEC),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _activeRoleLabel(user.role),
              style: TextStyle(
                color: Color(0xFF166534),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _heroAction(
              icon: Icons.edit,
              label: 'Edit Profile',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditUserScreen(
                      user: user,
                      allowedRoles: [user.role],
                    ),
                  ),
                );
                if (result == true) {
                  await _loadUser();
                  _loadTransactions();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F5F9),
        foregroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _contact(User user) {
    return _section(
      title: 'Contact Details',
      child: Column(
        children: [
          _item(Icons.mail, 'Email Address', user.email ?? '-', divider: true),
          _item(Icons.phone, 'Phone Number', user.phone ?? '-'),
        ],
      ),
    );
  }

  Widget _transaction() {
    return _section(
      title: 'Transaction History',
      trailing: TextButton(
        onPressed: _loadTransactions,
        child: const Text('Refresh'),
      ),
      child: loadingTransactions
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          : transactions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No transactions found.'),
                )
              : Column(
                  children: transactions
                      .map(
                        (o) => _transactionItem(
                          'Order #${o.id}',
                          '${o.status ?? '-'} • ${_formatDate(o.createdAt)}',
                          '\$${(o.total ?? 0).toStringAsFixed(2)}',
                          Icons.shopping_bag,
                          positive: o.status == OrderService.delivered,
                        ),
                      )
                      .toList(),
                ),
    );
  }

  String _formatDate(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _activeRoleLabel(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized.isEmpty) return 'Active User';
    return 'Active ${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  Widget _logout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: OutlinedButton.icon(
        onPressed: () async {
          await AuthService().logout();
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout, color: Color(0xFFE11D48)),
        label: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFE11D48),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: .7,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, String value, {bool divider = false}) {
    return Container(
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0x1A135BEC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF135BEC)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _transactionItem(
    String title,
    String subtitle,
    String amount,
    IconData icon, {
    bool positive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFF8FAFC),
        child: Icon(icon, color: const Color(0xFF475569), size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: positive ? const Color(0xFF15803D) : Colors.black,
        ),
      ),
    );
  }
}
