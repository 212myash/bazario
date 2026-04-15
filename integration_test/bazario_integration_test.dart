import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bazario/core/network/api_client.dart';
import 'package:bazario/core/network/session_events.dart';
import 'package:bazario/features/auth/presentation/providers/auth_provider.dart';
import 'package:bazario/features/cart/presentation/providers/cart_provider.dart';
import 'package:bazario/features/order/data/payment_gateway_provider.dart';
import 'package:bazario/features/order/presentation/providers/checkout_provider.dart';
import 'package:bazario/features/order/presentation/providers/order_provider.dart';
import 'package:bazario/features/product/presentation/providers/product_provider.dart';
import 'package:bazario/features/profile/presentation/providers/profile_provider.dart';
import 'package:bazario/features/wishlist/presentation/providers/wishlist_provider.dart';
import 'package:bazario/main.dart';

import 'test_fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Auth flow: login stores token and redirects to home', (
    tester,
  ) async {
    final tokenStorage = FakeTokenStorage();
    final container = _createContainer(
      tokenStorage: tokenStorage,
      paymentGateway: FakePaymentGateway(),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);

    expect(find.text('Welcome to Bazario'), findsOneWidget);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(await tokenStorage.getAccessToken(), 'token_123');
    expect(container.read(authProvider).isLoggedIn, isTrue);
    expect(find.text('Search products...'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Auth flow: token expiry triggers auto logout', (tester) async {
    final tokenStorage = FakeTokenStorage();
    final sessionEvents = SessionEvents();
    final container = _createContainer(
      tokenStorage: tokenStorage,
      sessionEvents: sessionEvents,
      paymentGateway: FakePaymentGateway(),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(container.read(authProvider).isLoggedIn, isTrue);

    sessionEvents.emitUnauthorized();
    await tester.pumpAndSettle();

    expect(container.read(authProvider).isLoggedIn, isFalse);
    expect(find.text('Welcome to Bazario'), findsOneWidget);
    expect(find.text('Search products...'), findsNothing);
  });

  testWidgets('Checkout flow: success callback creates order and navigates', (
    tester,
  ) async {
    final tokenStorage = FakeTokenStorage();
    final paymentGateway = FakePaymentGateway(autoSuccess: true);
    final container = _createContainer(
      tokenStorage: tokenStorage,
      paymentGateway: paymentGateway,
      checkoutApiService: FakeCheckoutApiService(),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Proceed to Checkout'), findsOneWidget);
    await tester.tap(find.text('Proceed to Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Checkout'), findsOneWidget);
    await tester.tap(find.text('John User'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay with Razorpay'));
    await tester.pumpAndSettle();

    expect(find.text('My Orders'), findsOneWidget);
    expect(
      container.read(checkoutProvider).currentOrder?.id,
      'order_checkout_1',
    );
  });

  testWidgets('Checkout flow: failure callback shows error message', (
    tester,
  ) async {
    final tokenStorage = FakeTokenStorage();
    final paymentGateway = FakePaymentGateway(
      autoSuccess: false,
      autoError: true,
    );
    final container = _createContainer(
      tokenStorage: tokenStorage,
      paymentGateway: paymentGateway,
      checkoutApiService: FakeCheckoutApiService(),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proceed to Checkout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('John User'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay with Razorpay'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Payment failed'), findsOneWidget);
  });

  testWidgets('Orders module: pagination and order details fetch work', (
    tester,
  ) async {
    final tokenStorage = FakeTokenStorage();
    final container = _createContainer(
      tokenStorage: tokenStorage,
      paymentGateway: FakePaymentGateway(),
      orderApiService: FakeOrderApiService(),
    );
    addTearDown(container.dispose);

    await _pumpApp(tester, container);
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ORDER_1'), findsOneWidget);
    expect(find.textContaining('ORDER_2'), findsNothing);

    await container.read(orderProvider.notifier).loadMore();
    await tester.pumpAndSettle();

    expect(find.textContaining('ORDER_2'), findsOneWidget);

    await tester.tap(find.textContaining('ORDER_1'));
    await tester.pumpAndSettle();

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Shipping Address'), findsOneWidget);
    expect(find.text('Demo Product'), findsOneWidget);
  });
}

ProviderContainer _createContainer({
  FakeTokenStorage? tokenStorage,
  SessionEvents? sessionEvents,
  FakeAuthApiService? authApiService,
  FakeProductApiService? productApiService,
  FakeCartApiService? cartApiService,
  FakeProfileApiService? profileApiService,
  FakeWishlistApiService? wishlistApiService,
  FakeOrderApiService? orderApiService,
  FakeCheckoutApiService? checkoutApiService,
  FakePaymentGateway? paymentGateway,
}) {
  return ProviderContainer(
    overrides: [
      if (tokenStorage != null)
        tokenStorageProvider.overrideWithValue(tokenStorage),
      if (sessionEvents != null)
        sessionEventsProvider.overrideWithValue(sessionEvents),
      authApiServiceProvider.overrideWithValue(
        authApiService ?? FakeAuthApiService(),
      ),
      productApiServiceProvider.overrideWithValue(
        productApiService ?? FakeProductApiService(),
      ),
      cartApiServiceProvider.overrideWithValue(
        cartApiService ?? FakeCartApiService(),
      ),
      profileApiServiceProvider.overrideWithValue(
        profileApiService ?? FakeProfileApiService(),
      ),
      wishlistApiServiceProvider.overrideWithValue(
        wishlistApiService ?? FakeWishlistApiService(),
      ),
      orderApiServiceProvider.overrideWithValue(
        orderApiService ?? FakeOrderApiService(),
      ),
      checkoutApiServiceProvider.overrideWithValue(
        checkoutApiService ?? FakeCheckoutApiService(),
      ),
      paymentGatewayProvider.overrideWithValue(
        paymentGateway ?? FakePaymentGateway(),
      ),
    ],
  );
}

Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const BazarioApp()),
  );
  await tester.pumpAndSettle();
}
