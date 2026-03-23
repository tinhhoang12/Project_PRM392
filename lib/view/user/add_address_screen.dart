import 'package:flutter/material.dart';
import '../../service/address_service.dart';
import '../../entity/address.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address;

  const AddAddressScreen({this.address, Key? key}) : super(key: key);

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
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
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  bool isDefault = false;

  final service = AddressService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Address")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Label (Home, Office)"),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: "Phone"),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: "Address"),
            ),

            Row(
              children: [
                Checkbox(
                  value: isDefault,
                  onChanged: (v) {
                    setState(() {
                      isDefault = v!;
                    });
                  },
                ),
                Text("Set as default")
              ],
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty ||
                    addressController.text.isEmpty) {
                  return;
                }

                final newAddress = Address(
                  id: widget.address?.id ?? 0,
                  userId: 1,
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

                Navigator.pop(context, true);
              },
              child: Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}