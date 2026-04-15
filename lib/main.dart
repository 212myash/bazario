import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/network/session_events.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BazarioApp()));
}

class BazarioApp extends ConsumerStatefulWidget {
  const BazarioApp({super.key});

  @override
  ConsumerState<BazarioApp> createState() => _BazarioAppState();
}

class _BazarioAppState extends ConsumerState<BazarioApp> {
  StreamSubscription<void>? _sessionSubscription;

  @override
  void initState() {
    super.initState();

    // Auto logout when the API reports unauthorized (401).
    _sessionSubscription = ref.read(sessionEventsProvider).stream.listen((_) {
      ref.read(authProvider.notifier).forceLogoutLocal();
    });
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
    );
  }
}
