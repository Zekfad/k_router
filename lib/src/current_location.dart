import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'location.dart';


@internal
const currentLocationFactory = CurrentLocation._;

/// {@template k_router_current_location_di}
/// Provides dependency injection of [Location] to it's built body.
/// {@endtemplate}
class CurrentLocation extends InheritedWidget {
  /// @nodoc
  const CurrentLocation._({
    required this.location,
    required super.child,
    super.key,
  });

  /// Location.
  final Location<Object?> location;

  /// Try to retrieve [Location] in which this [context] is contained.
  static Location<Object?>? maybeOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<CurrentLocation>()?.location;

  /// Retrieve [Location] in which this [context] is contained.
  static Location<Object?> of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No CurrentLocation found in context');
    return result!;
  }
  
  @override
  bool updateShouldNotify(covariant CurrentLocation oldWidget) =>
    !identical(oldWidget.location, location);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('location', location));
  }
}
