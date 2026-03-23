import 'package:flutter/material.dart';

import '../../entity/address.dart';
import '../../service/address_service.dart';
import '../../service/auth_service.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address;

  const AddAddressScreen({this.address, Key? key}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  bool isDefault = false;

  final service = AddressService();
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      nameController.text = widget.address!.name;
      phoneController.text = widget.address!.phone;
      addressController.text = widget.address!.address;
      isDefault = widget.address!.isDefault == 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Address')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Label (Home, Office)'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            Row(
              children: [
                Checkbox(
                  value: isDefault,
                  onChanged: (v) {
                    setState(() {
                      isDefault = v ?? false;
                    });
                  },
                ),
                const Text('Set as default')
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty ||
                    addressController.text.isEmpty) {
                  return;
                }

                final userId = await authService.getCurrentUserId();
                if (userId == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ban can dang nhap.')),
                  );
                  return;
                }

                final newAddress = Address(
                  id: widget.address?.id ?? 0,
                  userId: userId,
                  name: nameController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                  isDefault: isDefault ? 1 : 0,
                );

                if (widget.address == null) {
                  await service.insert(newAddress);
                } else {
                  await service.update(newAddress);
                }

                if (!mounted) return;
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
