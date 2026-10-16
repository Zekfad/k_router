import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'current_location.dart';
import 'k_navigator.dart';
import 'location.dart';
import 'location_error_page_builder.dart';
import 'location_stack.dart';
import 'location_stack_item.dart';


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
  /// Builder for replacement [Page] for when location builder fails.
  final LocationErrorPageBuilder? errorBuilder;

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
  void dispose() {
    currentConfiguration.dispose();
    super.dispose();
  }

  @override
  Future<bool> popRoute() {
    // code is identical to [KNavigator.getPopTargetLocation], except here
    // navigator is used instead of location
    final leaf = currentConfiguration.leafActiveItem;

    // check if leaf's navigator has some blocking overlay, such as drawer.
    late Route<Object?> leafsNavigatorTopRoute;
    leaf.outerNavigatorKey.currentState!.popUntil((route) {
      leafsNavigatorTopRoute = route;
      return true;
    });
    if (leafsNavigatorTopRoute.willHandlePopInternally) {
      return leaf.outerNavigatorKey.currentState!.maybePop();
    }

    // popping leaf is possible, so we traverse up to nearest navigator that can
    // pop
    // may target outer shell or multi shell, and [outerNavigatorKey] is of that
    // target shell/multi shell
    var result = leaf.removeTarget?.outerNavigatorKey.currentState;
    var parentRoute = ModalRoute.of(leaf.outerNavigatorKey.currentContext!);
    while (parentRoute != null) {
      // parent route is blocked by dialog: we target it's navigator
      if (!parentRoute.isCurrent) {
        final parentNavigator = parentRoute.navigator!;
        final surroundingLocation = CurrentLocation.maybeOf(parentNavigator.context, listen: false);
        if (surroundingLocation == null) {
          assert(parentNavigator == navigatorKey.currentState, 'invalid state');
          // its root navigator and it doesn't have any surrounding location
          return parentNavigator.maybePop();
        }
        final parentItem = LocationStackItem.locationCache[surroundingLocation]!;
        result = parentItem.removeTarget?.outerNavigatorKey.currentState;
        parentRoute = ModalRoute.of(parentItem.outerNavigatorKey.currentContext!);
      } else {
        parentRoute = ModalRoute.of(parentRoute.navigator!.context);
      }
    }
    return result?.maybePop()
      // cannot remove last page, so we let root navigator decide
      ?? navigatorKey.currentState!.maybePop();
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

  /// Trigger update:
  ///
  /// * Rebuild root navigator.
  /// * Update platform's state (URI and restoration data).
  void triggerUpdate() => notifyListeners();
}
