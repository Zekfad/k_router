import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal_locations.dart';
import 'location_codec.dart';
import 'location_stack.dart';
import 'location_stack_item.dart';
import 'location_stack_items_list.dart';


/// K Router information parser.
/// Turns router state into serializable format and parses it back.
/// Used as part of state restoration, browser navigation and deep linking.
class AppRouteInformationParser extends RouteInformationParser<LocationStack> {
  /// @nodoc
  @internal
  const AppRouteInformationParser({
    required this.locationCodecs,
  });

  static const _kDebugValidateCache = false;
  static const _kDebugEncoding = false;

  /// Maps discriminator integer to location codec.
  final LocationCodecMap locationCodecs;

  @override
  Future<LocationStack> parseRouteInformation(RouteInformation routeInformation) {
    // inspect(routeInformation);
    switch (routeInformation.state) {
      case final Map<Object?, Object?> map:
        // Recreate configuration from primitive state on restoration/initial start
        // or browser navigation
        if (!kReleaseMode) {
          Timeline.startSync('AppRouteInformationParser#decodeStack');
        }
        // preserve global id (used for item reuse in browser)
        if (map['g'] case final int globalId) {
          LocationStackItem.globalId = math.max(LocationStackItem.globalId, globalId);
        }
        final decodedStack = _decodeStack(map);
        if (!kReleaseMode) {
          Timeline.finishSync();
        }
        return SynchronousFuture(decodedStack);
      case final LocationStack preParsedConfiguration:
        return SynchronousFuture(preParsedConfiguration);
      case null:
        return SynchronousFuture(LocationStack.initial(
          UnknownLocation(uri: routeInformation.uri),
        ));
      default:
        throw FormatException('Invalid route information', routeInformation);
    }
  }

  @override
  RouteInformation restoreRouteInformation(LocationStack configuration) {
    // Convert configuration to primitive state
    if (!kReleaseMode) {
      Timeline.startSync('AppRouteInformationParser#encodeStack');
    }
    final encodedStack = _encodeStack(configuration)
      ..['g'] = LocationStackItem.globalId;
    if (!kReleaseMode) {
      Timeline.finishSync();
    }
    final routeInformation = RouteInformation(
      uri: configuration.leafActiveItem.location.uri,
      state: encodedStack,
    );

    if (kDebugMode && _kDebugEncoding) {
      debugPrint('Restore: ${routeInformation.uri}: ${
        const JsonEncoder.withIndent('  ').convert(routeInformation.state)
      }');
    }
    return routeInformation;
  }

  Map<Object?, Object?> _encodeStack(LocationStack stack) {
    final children = stack.items.toList();
    final active = stack.activeItem;
    final encodedChildren = <Map<Object?, Object?>>[];
    for (final item in children) {
      final codec = locationCodecs[item.location.discriminator.discriminator] ??
        locationCodecs[InternalLocations.unknown.discriminator] ??
        const LocationCodec();
      assert(
        !_kDebugValidateCache
        || item.encoded == null
        || const DeepCollectionEquality().equals(item.encoded, codec.encode(item.location)),
        'invalid cache',
      );
      encodedChildren.add({
        'l': item.encoded ??= codec.encode(item.location),
        'i': item.id,
        'c': _encodeStack(item.children),
      });
    }
    return {
      'a': active == null ? null : children.indexOf(active),
      'c': encodedChildren,
    };
  }

  LocationStack _decodeStack(Map<Object?, Object?> data) {
    if (data case {
      'a': final int? active,
      'c': final List<Object?> children,
    }) {
      LocationStackItem? activeItem;
      final stackChildren = LocationStackItemsList();
      for (final (i, child) in children.indexed) {
        if (child case {
          'l': { 'd': final int discriminator, } && final Map<Object?, Object?> location,
          'i': final int id,
          'c': final Map<Object?, Object?> childStackData,
        }) {
          final childStack = _decodeStack(childStackData);
          final cached = LocationStack.cachedItems[id];
          if (cached != null) {
            cached.stack.detachItem(cached);
            // we must rebuild page because build depends on children stack
            // which we replace
            cached.page = null;
            // we can dispose children because this call will first happen in
            // the deepest part of recursion.
            cached.children.dispose();
            cached.children = childStack
              ..parentItem = cached;
          }
          final item = cached ?? LocationStackItem(
            location: (
              locationCodecs[discriminator] ??
              locationCodecs[InternalLocations.unknown.discriminator] ??
              const LocationCodec()
            ).decode(location),
            children: childStack,
          );
          stackChildren.add(item);
          if (i == active) {
            activeItem = item;
          }
        } else {
          throw FormatException('Invalid stack item', data);
        }
      }
      return LocationStack(
        children: stackChildren,
        activeItem: activeItem,
      );
    } else {
      throw FormatException('Invalid format of stack', data);
    }
  }
}
