import 'package:flutter/widgets.dart';

import 'deep_link_result.dart';
import 'k_route_information_parser.dart';
import 'k_route_information_provider.dart';
import 'k_router_delegate.dart';
import 'location.dart';
import 'location_codec.dart';
import 'location_stack.dart';


/// {@template k_router_router_config}
/// Router config crates and configures router delegate, parser, provider and
/// back handler.
/// 
/// This is the only intended router initialization, because some parts are very
/// tightly connected and requires specific configuration to work property.
/// {@endtemplate}
class KRouterConfig extends RouterConfig<LocationStack> {
  /// {@macro k_router_router_config}
  /// 
  /// [initialLocation] is used as initial location and may be build at least
  /// once even if it's never used.
  /// 
  /// [locationCodecs] map is used to (de)serialize locations for state
  /// restoration and browser navigation. This map is required and __MUST__
  /// contain codecs for every user [Location].
  /// 
  /// [onDeepLink] is a deep link handler function, if `null` deep links
  /// handling is disabled (which is fine for mobile apps, but can leave you in
  /// broken state in browser if user changes URL). Initial deep link is also
  /// handled by this function and can replace [initialLocation] when
  /// [DeepLinkResult.replaceStack] is returned.
  factory KRouterConfig({
    required Location<Object?> initialLocation,
    required LocationCodecMap locationCodecs,
    DeepLinkHandler? onDeepLink,
  }) {
    final delegate = KRouterDelegate(initialLocation);
    final parser = KRouteInformationParser(
      locationCodecs: locationCodecs,
    );
    final initialUri = WidgetsFlutterBinding.ensureInitialized().platformDispatcher.defaultRouteName;
    final LocationStack currentConfiguration;
    if (initialUri == '/' || onDeepLink == null) {
      currentConfiguration = delegate.currentConfiguration;
    } else {
      // handle initial deep link
      currentConfiguration = switch (onDeepLink(Uri.parse(initialUri))) {
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
      };
    }
    final provider = KRouteInformationProvider(
      initialRouteInformation: RouteInformation(
        uri: currentConfiguration.leafActiveItem.location.uri,
        state: currentConfiguration,
      ),
      deepLinkHandler: onDeepLink,
      delegate: delegate,
    );
    return KRouterConfig._(
      routeInformationProvider: provider,
      routeInformationParser: parser,
      routerDelegate: delegate,
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
  }

  KRouterConfig._({
    required super.routeInformationProvider,
    required super.routeInformationParser,
    required super.routerDelegate,
    required super.backButtonDispatcher,
  });
}
