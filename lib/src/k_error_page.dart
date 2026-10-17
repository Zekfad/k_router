/// @docImport 'k_router_delegate.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';


/// Fallback error page, when no [KRouterDelegate.errorBuilder] is specified.
@internal
class KErrorPage extends Page<void> {
  /// Create new error page with [error] and optional [stackTrace].
  const KErrorPage({
    required this.error,
    this.stackTrace,
    super.canPop,
    super.onPopInvoked,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// [Exception] or [Error] object.
  final Object error;
  /// Stack trace.
  final StackTrace? stackTrace;

  @override
  Route<void> createRoute(BuildContext context) =>
    _KErrorRoute(settings: this);
}

class _KErrorRoute extends PageRoute<void> {
  _KErrorRoute({
    required KErrorPage super.settings,
  });

  @override
  Color? get barrierColor => const Color(0x00000000);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final page = settings as KErrorPage;
    return SingleChildScrollView(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: ErrorWidget(
          FlutterError.fromParts([
            ErrorSummary('Failed to build the page, tap to pop'),
            DiagnosticsProperty('Error', page.error),
            DiagnosticsProperty('StackTrace', page.stackTrace),
          ]),
        )
      ),
    );
  }
}
