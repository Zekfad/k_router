import 'package:flutter/widgets.dart';


/// Notification that is dispatched whenever navigation stack changes.
class LocationStackChangeNotification extends Notification {
  /// Create new location stack change notification.
  const LocationStackChangeNotification({
    required this.navigatorKey
  });

  /// Key of navigator associated with changed stack.
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('navigatorKey: $navigatorKey');
  }
}
