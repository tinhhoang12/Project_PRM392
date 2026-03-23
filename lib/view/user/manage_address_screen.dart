import 'package:flutter/material.dart';

import '../../entity/address.dart';
import '../../service/address_service.dart';
import '../../service/auth_service.dart';
import 'add_address_screen.dart';

class ManageAddressScreen extends StatefulWidget {
  const ManageAddressScreen({super.key});

  @override
  State<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  final _addressService = AddressService();
  final _authService = AuthService();

  bool _loading = true;
  int? _userId;
  List<Address> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final uid = await _authService.getCurrentUserId();
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _userId = null;
        _addresses = [];
        _loading = false;
      });
      return;
    }

    final data = await _addressService.getAll(uid);
    if (!mounted) return;
    setState(() {
      _userId = uid;
      _addresses = data;
      _loading = false;
    });
  }

  Future<void> _openAddOrEdit(Address? address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAddressScreen(address: address)),
    );
    if (result == true) {
      await _loadAddresses();
    }
  }

  Future<void> _setDefault(Address address) async {
    if (_userId == null) return;
    final updated = Address(
      id: address.id,
      userId: _userId!,
      name: address.name,
      phone: address.phone,
      address: address.address,
      isDefault: 1,
    );
    await _addressService.update(updated);
    await _loadAddresses();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default address updated.')),
    );
  }

  Future<void> _deleteAddress(Address address) async {
    if (_userId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await _addressService.delete(address.id, _userId!);
    await _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      appBar: AppBar(
        title: const Text('Manage Addresses'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off_outlined,
                          size: 54,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No addresses yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add your first delivery address.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => _openAddOrEdit(null),
                          icon: const Icon(Icons.add_location_alt),
                          label: const Text('Add New'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    ..._addresses.map(_addressCard),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _openAddOrEdit(null),
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Add New Address'),
                    ),
                  ],
                ),
    );
  }

  Widget _addressCard(Address a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: a.isDefault == 1 ? const Color(0xFF135BEC) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (a.isDefault == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(a.address),
          const SizedBox(height: 2),
          Text(
            a.phone,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (a.isDefault != 1)
                TextButton(
                  onPressed: () => _setDefault(a),
                  child: const Text('Set as default'),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => _openAddOrEdit(a),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: () => _deleteAddress(a),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          )
        ],
      ),
    );
  }
}
