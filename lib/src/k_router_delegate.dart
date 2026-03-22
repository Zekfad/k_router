import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'k_navigator.dart';
import 'location.dart';
import 'location_error_widget_builder.dart';
import 'location_stack.dart';


/// Signature for callback that is executed next frame after router is
/// initialized. [isRestored] shows whether app was restored or cold started.
typedef OnDidInitialize = void Function(GlobalKey<NavigatorState> navigatorKey, bool isRestored);

/// K Router delegate manages [KNavigator] and processes updates from
/// route provider.
class KRouterDelegate extends RouterDelegate<LocationStack> with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  /// @nodoc
  @internal
  KRouterDelegate({
    required Location<Object?> initialLocation,
    this.onDidInitialize,
    this.errorBuilder,
  }) : currentConfiguration = LocationStack.initial(initialLocation) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: 'k#root');

  /// Callback that is executed next frame after router is initialized.
  final OnDidInitialize? onDidInitialize;
  /// Builder for replacement widget if location page builder failed.
  final LocationErrorWidgetBuilder? errorBuilder;

  @override
  LocationStack currentConfiguration;

  @override
  Future<void> setNewRoutePath(LocationStack configuration) {
    if (!identical(currentConfiguration, configuration)) {
      currentConfiguration.dispose();
    }
    currentConfiguration = configuration;
    return SynchronousFuture(null);
  }

  @override
  Future<void> setInitialRoutePath(LocationStack configuration) {
    final result = setNewRoutePath(configuration);
    _onDidInitialize(false);
    return result;
  }

  @override
  Future<void> setRestoredRoutePath(LocationStack configuration) {
    final result = setNewRoutePath(configuration);
    _onDidInitialize(true);
    return result;
  }

  void _onDidInitialize(bool isRestored) {
    if (onDidInitialize case final callback?) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => callback(navigatorKey, isRestored),
        debugLabel: 'KRouterDelegate#_onDidInitialize'
      );
    }
  }

  @override
  Future<bool> popRoute() {
    final leaf = currentConfiguration.leafActiveItem;
    final target = leaf.removeTarget;
    if (target == null) {
      // cannot remove last page, so we let root navigator decide
      return navigatorKey.currentState!.maybePop();
    }
    final navigatorState = target.outerNavigatorKey.currentState!;
    return navigatorState.maybePop();
  }

  @override
  Widget build(BuildContext context) => kNavigatorFactory(
    root: true,
    delegate: this,
    stack: currentConfiguration,
    restorationScopeId: 'router_root',
    navigatorKey: navigatorKey,
    errorBuilder: errorBuilder,
  );

  @override
  void dispose() {
    currentConfiguration.dispose();
    super.dispose();
  }

  /// Trigger update:
  ///
  /// * Rebuild root navigator.
  /// * Update platform's state (URI and restoration data).
  void triggerUpdate() => notifyListeners();
}
