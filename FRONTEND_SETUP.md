# Bazario Flutter Frontend Setup (Phase 1)

This document covers the completed **project setup + base architecture** for the Flutter app connected to the Bazario backend.

## 1. Folder Structure

```text
lib/
  core/
    constants/
      app_constants.dart
    network/
      api_client.dart
    router/
      app_router.dart
    theme/
      app_theme.dart
    utils/
      app_exception.dart
      token_storage.dart
  features/
    auth/
      data/
        auth_api_service.dart
      presentation/
        providers/
          auth_provider.dart
        screens/
          login_screen.dart
          register_screen.dart
    product/
      data/
        product_api_service.dart
      presentation/
        providers/
          product_provider.dart
        screens/
          home_screen.dart
          product_details_screen.dart
    cart/
      data/
        cart_api_service.dart
      presentation/
        providers/
          cart_provider.dart
        screens/
          cart_screen.dart
    order/
      presentation/
        screens/
          orders_screen.dart
    profile/
      presentation/
        screens/
          profile_screen.dart
    wishlist/
      presentation/
        screens/
          wishlist_screen.dart
  shared/
    models/
      cart_model.dart
      category_model.dart
      product_model.dart
      user_model.dart
    widgets/
      app_button.dart
      app_text_field.dart
      error_state_view.dart
      loading_skeleton.dart
      product_card.dart
  main.dart
```

## 2. Dependencies Added

- flutter_riverpod
- go_router
- dio
- shared_preferences
- flutter_secure_storage
- cached_network_image
- shimmer
- intl
- razorpay_flutter
- cupertino_icons

## 3. Theme Setup

- Light and dark theme are configured in `lib/core/theme/app_theme.dart`
- Material 3 design tokens are enabled
- Card/input styles are standardized for reusable UI consistency

## 4. API Service Layer (Dio)

- Base Dio client and interceptor are in `lib/core/network/api_client.dart`
- Access token is injected into `Authorization` header automatically
- Token is stored using secure storage (`lib/core/utils/token_storage.dart`)
- Feature API classes:
  - Auth: `lib/features/auth/data/auth_api_service.dart`
  - Products: `lib/features/product/data/product_api_service.dart`
  - Cart: `lib/features/cart/data/cart_api_service.dart`

## 5. Auth Flow (Implemented)

- Login and register screens are implemented
- Auto-login checks stored token on app start
- Logout clears local token
- Auth state is managed with Riverpod StateNotifier

## 6. Product Listing (Implemented)

- Home screen fetches products from backend
- Search input with debounce
- Category chips loaded from categories API
- Product grid with reusable product cards
- Loading skeleton and error state handling included

## 7. Cart Integration (Implemented)

- Fetch cart from backend
- Add to cart from product cards/details
- Update quantity in cart screen
- Remove cart item
- Total amount calculated from snapshots

## 8. Backend Connection Steps

1. Start backend (inside `backend/`):
   - `npm run dev`
2. Start Flutter app (root project):
   - `flutter run`
3. Ensure base URL points to your backend:
   - Android emulator default is already set to `http://10.0.2.2:5000`
   - For physical device or deployed backend, run with:
     - `flutter run --dart-define=BAZARIO_BASE_URL=https://your-api-url`

## 9. Run Instructions

1. `flutter pub get`
2. `flutter analyze`
3. `flutter run`

## 10. Current Status

Completed in this phase:
- Project setup and dependencies
- Clean architecture base scaffold
- Router + bottom navigation shell
- Auth module (login/register/auto-login/logout)
- Product listing and product detail base
- Cart module API integration and UI
- Theme, loading states, error states, reusable widgets

Next phase to implement fully:
- Wishlist APIs and UI binding
- Orders history/detail/status tracking
- Profile APIs + address management
- Checkout + Razorpay test flow
- Reviews and ratings UI/actions
