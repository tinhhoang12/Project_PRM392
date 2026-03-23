import 'package:flutter/material.dart';
import '../../service/address_service.dart';
import '../../entity/address.dart';
import 'checkout_payment_screen.dart';
import 'add_address_screen.dart';


class CheckoutAddressScreen extends StatefulWidget {
  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}


class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> {
  final addressService = AddressService();
  List<Address> addresses = [];
  int? selectedAddressId;

  @override
  void initState() {
    super.initState();
    loadAddress();
  }

  Future<void> loadAddress() async {
    final data = await addressService.getAll(1);
    setState(() {
      addresses = data;
      // chọn mặc định
      final defaultAddress = data.firstWhere((e) => e.isDefault == 1, orElse: () => data.first);
      selectedAddressId = defaultAddress.id;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f6f8),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER + STEPPER
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Shipping Address",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _stepCircle(1, true),
                        _stepLine(),
                        _stepCircle(2, false),
                        _stepLine(),
                        _stepCircle(3, false),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _stepLabel("Address", true),
                        SizedBox(width: 32),
                        _stepLabel("Payment", false),
                        SizedBox(width: 32),
                        _stepLabel("Confirm", false),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Saved Addresses", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(
                          "${addresses.length} Addresses found",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...addresses.map((item) => _addressTile(item)).toList(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text("Add New Address"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddAddressScreen()),
                          );
                          if (result == true) loadAddress();
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // MAP/STATUS
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBzHuQQhPYjiCUk0lmDwa-R85ZSNPQpE4ADJUkM3fhznXrDx58_SD5n0bZcF0QIqB64D-Tr7bX94XO9iaghBotj6QI2FgZ_Xhopjbr4i_55RIIev-P8vRWfCEZb5lauQkQ-vaikmCHzoCwa8XQRYmM63g_NvVONJ2MmuumXgeLcekSdWysz-vywaobt5O7f1ZnLUfHA-bIjKg7CtqXxQiyGCV1LSa0kWkgeoeBnOx2e2R6N6Mn2kUF7X-Yy9EPNoRi2cmKBochP8eo'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.map, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text("View nearby collection points", style: TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // FOOTER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xfff6f6f8))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135bec),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Continue to Payment", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: selectedAddressId == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutPaymentScreen(
                                addressId: selectedAddressId!,
                              ),
                            ),
                          );
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressTile(Address item) {
    final isSelected = selectedAddressId == item.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAddressId = item.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF135bec) : Colors.grey.shade300,
            width: 2,
          ),
          color: isSelected ? const Color(0x1A135bec) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<int>(
              value: item.id!,
              groupValue: selectedAddressId,
              activeColor: const Color(0xFF135bec),
              onChanged: (v) {
                setState(() {
                  selectedAddressId = v;
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (item.isDefault == 1)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF135bec),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("Default", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item.address, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  Text(item.phone, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            // TODO: Thêm nút edit/delete nếu cần
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddAddressScreen(address: item)),
                  );
                  if (result == true) loadAddress();
                },
              ),    

          ],
        ),
      ),
    );
  }

}

class _stepCircle extends StatelessWidget {
  final int step;
  final bool active;
  const _stepCircle(this.step, this.active, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF135bec) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? const Color(0xFF135bec) : Colors.grey.shade300, width: 2),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _stepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 2,
      color: Colors.grey.shade300,
    );
  }
}

class _stepLabel extends StatelessWidget {
  final String label;
  final bool active;
  const _stepLabel(this.label, this.active, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: active ? const Color(0xFF135bec) : Colors.grey,
        letterSpacing: 1.2,
        decoration: TextDecoration.none,
        fontFamily: 'Inter',
      ),
    );
  }
}