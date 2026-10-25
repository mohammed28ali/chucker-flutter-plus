import 'dart:typed_data';

import 'package:chucker_flutter_plus/src/config/dependency_injection/chucker_dependencies.dart';
import 'package:flutter/material.dart';

import '../../features/network_inspector/domain/entities/network_transaction.dart';
import '../../features/network_inspector/presentation/pages/network_inspector_page.dart';
import '../../features/network_inspector/presentation/pages/request_detail_page.dart';
import '../../features/network_inspector/presentation/pages/settings_page.dart';
import 'routes_name.dart';

abstract final class AppRoutes {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    ChuckerDependencies? dependencies,
    VoidCallback? onClose,
    String? initialRequestId,
  }) {
    switch (settings.name) {
      case Routes.initialRoute:
      case Routes.networkInspector:
        final args = settings.arguments;
        final deps =
            dependencies ??
            (args is ChuckerDependencies ? args : ChuckerDependencies.create());
        final initialId = args is String
            ? args
            : (args is Map ? args['requestId'] as String? : initialRequestId);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => NetworkInspectorPage(
            dependencies: deps,
            initiallySelectedId: initialId,
            onClose: onClose,
          ),
        );

      case Routes.requestDetail:
        final transaction = settings.arguments as NetworkTransaction;
        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              RequestDetailPage(transaction: transaction),
          transitionsBuilder: (context, anim, secondaryAnim, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 250),
        );

      case Routes.settings:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const InspectorSettingsPage(),
        );

      case Routes.mediaPreview:
        final bytes = settings.arguments as Uint8List;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
          ),
        );

      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
