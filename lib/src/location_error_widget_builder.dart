/// @docImport 'k_router_delegate.dart';
library;

import 'package:flutter/widgets.dart';


/// Signature used by [KRouterDelegate.errorBuilder] to create a replacement
/// widget to render instead of the location when an irrecoverable error occurs.
typedef LocationErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  StackTrace? stackTrace,
);
