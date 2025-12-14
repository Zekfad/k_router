import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_router_delegate.dart';
import 'deep_link_result.dart';
import 'location_stack.dart';


/// K Router information provider propagates platform route changes (deep links
/// and browser navigation) to router delegate.
class AppRouteInformationProvider extends PlatformRouteInformationProvider {
  /// @nodoc
  @internal
  AppRouteInformationProvider({
    required this.delegate,
    required super.initialRouteInformation,
    this.deepLinkHandler,
  });

  /// K Router delegate.
  final AppRouterDelegate delegate;
  /// Deep link handler.
  /// 
  /// If none provided deep linking functionality is disabled and all deep links
  /// are ignored.
  final DeepLinkHandler? deepLinkHandler;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    if (routeInformation.state == null) {
      // deep link handling
      if (deepLinkHandler case final handler?) {
        return super.didPushRouteInformation(
          RouteInformation(
            uri: routeInformation.uri,
            state: switch (handler(routeInformation.uri)) {
              DeepLinkIgnore() =>
                delegate.currentConfiguration,
              DeepLinkPush(:final location) =>
                delegate.currentConfiguration..leafActiveItem.stack.pushLocation(location)
                  .catchError(LocationStack.popErrorHandler).ignore(),
              DeepLinkPushToRoot(:final location) =>
                delegate.currentConfiguration..pushLocation(location)
                  .catchError(LocationStack.popErrorHandler).ignore(),
              DeepLinkReplaceStack(:final location) =>
                LocationStack.initial(location),
            },
          ),
        );
      }
      return SynchronousFuture(false);
    }
    return super.didPushRouteInformation(routeInformation);
  }
}
