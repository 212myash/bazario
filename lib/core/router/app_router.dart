import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/order/presentation/screens/checkout_screen.dart';
import '../../features/order/presentation/screens/order_details_screen.dart';
import '../../features/order/presentation/screens/orders_screen.dart';
import '../../features/product/presentation/screens/storefront_dashboard_screen.dart';
import '../../features/product/presentation/screens/product_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/shipping_address_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/startup_gate_screen.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(
    authProvider.select((state) => state.isLoggedIn),
  );
  final userRole = ref.watch(
    authProvider.select((state) => state.user?.role.toLowerCase() ?? ''),
  );

  return GoRouter(
    initialLocation: '/startup',
    redirect: (context, state) {
      final isAdmin = userRole == 'admin';
      final isStartupRoute = state.matchedLocation == '/startup';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final isLoginRoute = state.matchedLocation == '/login';
      final signedInHome = isAdmin ? '/admin' : '/home';

      if (!isLoggedIn &&
          !(isStartupRoute || isOnboardingRoute || isLoginRoute)) {
        return '/login';
      }

      if (isLoggedIn && (isOnboardingRoute || isLoginRoute || isStartupRoute)) {
        return signedInHome;
      }

      if (isLoggedIn &&
          state.matchedLocation.startsWith('/admin') &&
          !isAdmin) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/startup',
        builder: (context, state) => const StartupGateScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          return _BaseShell(navigationShell: shell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const StorefrontDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:slug',
                    builder: (context, state) {
                      final slug = state.pathParameters['slug'] ?? '';
                      return ProductDetailsScreen(slug: slug);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wishlist',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const ProfileEditScreen(),
                  ),
                  GoRoute(
                    path: 'shipping-address',
                    builder: (context, state) => const ShippingAddressScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
        routes: [
          GoRoute(
            path: 'details/:orderId',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId'] ?? '';
              return OrderDetailsScreen(orderId: orderId);
            },
          ),
        ],
      ),
    ],
  );
});

class _BaseShell extends StatelessWidget {
  const _BaseShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
