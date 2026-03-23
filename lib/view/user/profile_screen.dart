import 'package:flutter/material.dart';

import '../../entity/user.dart';
import '../../service/auth_service.dart';
import '../../service/order_service.dart';
import '../../service/user_service.dart';
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import 'manage_address_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  bool loading = true;
  int ordersCount = 0;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final currentUser = await UserService().getCurrentUser();
    if (currentUser?.id != null) {
      final userOrders = await OrderService().getOrdersByUser(currentUser!.id!);
      ordersCount = userOrders.length;
    }
    if (!mounted) return;
    setState(() {
      user = currentUser;
      loading = false;
    });
  }

  Future<void> logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openManageAddresses() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageAddressScreen()),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    if (user?.id == null) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final authService = AuthService();
    final userService = UserService();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorText;

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (currentPassword.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                setDialogState(() {
                  errorText = 'Please fill all password fields.';
                });
                return;
              }

              if (newPassword.length < 6) {
                setDialogState(() {
                  errorText = 'New password must be at least 6 characters.';
                });
                return;
              }

              if (newPassword != confirmPassword) {
                setDialogState(() {
                  errorText = 'Confirm password does not match.';
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                errorText = null;
              });

              final latestUser = await userService.getUserById(user!.id!);
              if (latestUser == null) {
                setDialogState(() {
                  isSaving = false;
                  errorText = 'User not found. Please login again.';
                });
                return;
              }

              final validCurrent = authService.verifyPassword(
                rawPassword: currentPassword,
                storedPassword: latestUser.password,
              );
              if (!validCurrent) {
                setDialogState(() {
                  isSaving = false;
                  errorText = 'Current password is incorrect.';
                });
                return;
              }

              await userService.updateUser(
                User(
                  id: latestUser.id,
                  username: latestUser.username,
                  password: newPassword,
                  email: latestUser.email,
                  fullName: latestUser.fullName,
                  phone: latestUser.phone,
                  address: latestUser.address,
                  avatar: latestUser.avatar,
                  role: latestUser.role,
                  createdAt: latestUser.createdAt,
                ),
              );

              if (!mounted) return;
              Navigator.pop(dialogContext, true);
            }

            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(() {
                            obscureCurrent = !obscureCurrent;
                          }),
                          icon: Icon(
                            obscureCurrent ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(() {
                            obscureNew = !obscureNew;
                          }),
                          icon: Icon(
                            obscureNew ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(() {
                            obscureConfirm = !obscureConfirm;
                          }),
                          icon: Icon(
                            obscureConfirm ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Color(0xFFE11D48), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      await loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : user == null
                ? _guestProfile()
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _header(),
                      _profileHead(),
                      _accountSection(),
                      _securitySection(),
                      _logoutSection(),
                    ],
                  ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xfff6f6f8),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _guestProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 56,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            const Text(
              'Login Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please login to view your profile, orders, and account settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  await loadUser();
                },
                child: const Text('Go To Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHead() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 64,
                backgroundImage: (user!.avatar != null && user!.avatar!.isNotEmpty)
                    ? NetworkImage(user!.avatar!)
                    : const NetworkImage('https://i.pravatar.cc/300'),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(Icons.photo_camera,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user!.fullName ?? 'No Name',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user!.email ?? 'No Email',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('${ordersCount}', 'Orders'),
              const SizedBox(width: 10),
              _metric('4', 'Wishlist'),
              const SizedBox(width: 10),
              _metric('850', 'Points'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF135BEC),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountSection() {
    return _menuSection(
      title: 'Account Management',
      children: [
        _menuItem(
          icon: Icons.person,
          title: 'Edit Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditProfileScreen(user: user!)),
            ).then((_) => loadUser());
          },
        ),
        _menuItem(
          icon: Icons.location_on,
          title: 'Manage Addresses',
          onTap: _openManageAddresses,
        ),
        _menuItem(icon: Icons.credit_card, title: 'Payment Methods', onTap: () {}),
      ],
    );
  }

  Widget _securitySection() {
    return _menuSection(
      title: 'Security',
      children: [
        _menuItem(
          icon: Icons.lock,
          title: 'Security Settings',
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          onTap: _showChangePasswordDialog,
        ),
      ],
    );
  }

  Widget _menuSection({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: .8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(children: children),
          )
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconBg = const Color(0x1A135BEC),
    Color iconColor = const Color(0xFF135BEC),
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _logoutSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: logout,
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Version 2.4.1 (Build 10)',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
