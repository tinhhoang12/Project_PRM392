# Template To Flutter Mapping

All HTML templates in `lib/templates` have Flutter counterparts in `lib/view`.

## User Templates

- `templates/login.html` -> `view/login_screen.dart`
- `templates/home_screen.html` -> `view/user/home_screen.dart`
- `templates/product_category.html` -> `view/user/product_category_screen.dart`
- `templates/product_detail.html` -> `view/user/product_detail_screen.dart`
- `templates/cart.html` -> `view/user/cart_screen.dart`
- `templates/checkout_address.html` -> `view/user/checkout_address_screen.dart`
- `templates/checkout_payment.html` -> `view/user/checkout_payment_screen.dart`
- `templates/checkout_success_confirm.html` -> `view/user/checkout_success_screen.dart`
- `templates/order_history.html` -> `view/user/order_history_screen.dart`
- `templates/user_profile.html` -> `view/user/profile_screen.dart`

## Admin Templates

- `templates/admin/dashboard.html` -> `view/admin/admin_dashboard.dart`
- `templates/admin/product_management.html` -> `view/admin/product_management_screen.dart`
- `templates/admin/order_management.html` -> `view/admin/order_management_screen.dart`
- `templates/admin/user_management.html` -> `view/admin/user_management_screen.dart`
- `templates/admin/admin_profile.html` -> `view/admin/admin_profile_screen.dart`

## Notes

- The HTML folder is kept as design reference only.
- Runtime UI should use Flutter screens above.
