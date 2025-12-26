import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'k_navigator.dart';
import 'location.dart';
import 'location_stack.dart';


/// K Router delegate manages [KNavigator] and processes updates from
/// route provider. 
class KRouterDelegate extends RouterDelegate<LocationStack> with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  /// @nodoc
  @internal
  KRouterDelegate(
    Location<Object?> initialLocation,
  ) : currentConfiguration = LocationStack.initial(initialLocation) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: 'root navigator');

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
  Future<void> setRestoredRoutePath(LocationStack configuration) =>
    setNewRoutePath(configuration);

  @override
  Future<bool> popRoute() =>
    SynchronousFuture(currentConfiguration.leafActiveItem.remove());

  @override
  Widget build(BuildContext context) => kNavigatorFactory(
    delegate: this,
    stack: currentConfiguration,
    restorationScopeId: 'router_root',
    navigatorKey: navigatorKey,
    createHeroController: false,
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
