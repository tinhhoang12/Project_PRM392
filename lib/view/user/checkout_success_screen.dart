import 'package:flutter/material.dart';
import 'user_main_screen.dart';
import 'order_status_screen.dart';
import '../../service/auth_service.dart';

class CheckoutSuccessScreen extends StatelessWidget {
	final String orderId;
	final String paymentMethod;
	final double totalPaid;
	final String? estimatedDelivery;

	const CheckoutSuccessScreen({
		Key? key,
		required this.orderId,
		required this.paymentMethod,
		required this.totalPaid,
		this.estimatedDelivery,
	}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xfff6f6f8),
			body: SafeArea(
				child: Column(
					children: [
						// Header
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
							child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
									IconButton(
										icon: const Icon(Icons.close),
										onPressed: () => Navigator.of(context).pop(),
									),
									const Expanded(
										child: Center(
											child: Text(
												"Order Confirmation",
												style: TextStyle(
													fontWeight: FontWeight.bold,
													fontSize: 18,
												),
											),
										),
									),
									const SizedBox(width: 48),
								],
							),
						),

						// Success Icon
						const SizedBox(height: 24),
						Container(
							margin: const EdgeInsets.only(bottom: 12),
							height: 96,
							width: 96,
							decoration: BoxDecoration(
								color: const Color(0x1A135bec),
								borderRadius: BorderRadius.circular(48),
							),
							child: const Center(
								child: Icon(Icons.check_circle, color: Color(0xFF135bec), size: 64),
							),
						),
						const Text(
							"Order Placed Successfully!",
							style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
						),
						const SizedBox(height: 8),
						const Padding(
							padding: EdgeInsets.symmetric(horizontal: 32),
							child: Text(
								"Thank you for your purchase. Your order has been confirmed and is being prepared for shipment.",
								textAlign: TextAlign.center,
								style: TextStyle(color: Colors.grey, fontSize: 14),
							),
						),

						const SizedBox(height: 18),
						// Order Summary Card
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 24),
							child: Card(
								shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
								elevation: 1,
								child: Padding(
									padding: const EdgeInsets.all(20),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text("Order Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
											const SizedBox(height: 12),
											_row("Order ID", orderId),
											_row("Estimated Delivery", estimatedDelivery ?? "3-5 days"),
											_row("Payment Method", paymentMethod),
											const Divider(height: 28),
											Row(
												mainAxisAlignment: MainAxisAlignment.spaceBetween,
												children: [
													const Text("Total Paid", style: TextStyle(fontWeight: FontWeight.bold)),
													Text(
														"\$${totalPaid.toStringAsFixed(2)}",
														style: const TextStyle(
															color: Color(0xFF135bec),
															fontWeight: FontWeight.bold,
															fontSize: 18,
														),
													),
												],
											),
										],
									),
								),
							),
						),

						// Map/Status Preview
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
							child: Container(
								height: 100,
								decoration: BoxDecoration(
									borderRadius: BorderRadius.circular(16),
									image: const DecorationImage(
										image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDxHARSrauzcRGEG7tc5ZQ529e32R3ZAw6hT5jazrc_fKU8jAZK5ptazmcLZnMKb8S4z5tm1GWiEFTbuPpTZNoCALUblYy1F5bOsGLJ2jDkfF5Nh3xWCU9o1Q0t27d4cqIKZhDX3IDqe_jV4udVzaceMybgktIZsNVTmBRXnwDLsWWqrfo866KRpKBa_MBgk3i1RUsBspX-fiUP68pzE2OHvP0uEdA_CGb_d5twrQjPulg__gqJMXzaoq4Ya2CsLWbYh_enfbSmSps'),
										fit: BoxFit.cover,
										colorFilter: ColorFilter.mode(Colors.black12, BlendMode.darken),
									),
								),
								child: Center(
									child: Container(
										padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
										decoration: BoxDecoration(
											color: Colors.white,
											borderRadius: BorderRadius.circular(24),
											boxShadow: [
												BoxShadow(
													color: Colors.black.withOpacity(0.1),
													blurRadius: 8,
												),
											],
										),
										child: Row(
											mainAxisSize: MainAxisSize.min,
											children: const [
												Icon(Icons.circle, color: Color(0xFF135bec), size: 12),
												SizedBox(width: 8),
												Text("Order processing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
											],
										),
									),
								),
							),
						),

						// Actions
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 24),
							child: Column(
								children: [
									SizedBox(
										width: double.infinity,
										child: ElevatedButton.icon(
											style: ElevatedButton.styleFrom(
												backgroundColor: const Color(0xFF135bec),
												shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
												padding: const EdgeInsets.symmetric(vertical: 16),
											),
											icon: const Icon(Icons.local_shipping),
											label: const Text("Track Order", style: TextStyle(fontWeight: FontWeight.bold)),
																	onPressed: () async {
																		// Lấy userId hiện tại
																		final userId = await AuthService().getCurrentUserId();
																		if (userId != null) {
																			Navigator.of(context).push(
																				MaterialPageRoute(
																					builder: (_) => OrderStatusScreen(userId: userId),
																				),
																			);
																		} else {
																			// fallback: vẫn chuyển sang OrderStatusScreen nhưng không truyền userId
																			Navigator.of(context).push(
																				MaterialPageRoute(
																					builder: (_) => const OrderStatusScreen(),
																				),
																			);
																		}
																	},
										),
									),
									const SizedBox(height: 10),
									SizedBox(
										width: double.infinity,
										child: OutlinedButton(
											style: OutlinedButton.styleFrom(
												shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
												padding: const EdgeInsets.symmetric(vertical: 16),
											),
											child: const Text("Continue Shopping", style: TextStyle(fontWeight: FontWeight.bold)),
											onPressed: () {
												Navigator.of(context).pushAndRemoveUntil(
													MaterialPageRoute(builder: (_) => const UserMainScreen()),
													(route) => false,
												);
											},
										),
									),
								],
							),
						),

						// ...existing code...
					],
				),
			),
		);
	}

	static Widget _row(String label, String value) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 4),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
					Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
				],
			),
		);
	}
}

