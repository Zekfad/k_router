/// @docImport 'k_router_delegate.dart';
library;

import 'package:flutter/widgets.dart';


/// Signature used by [KRouterDelegate.errorBuilder] when an irrecoverable error
/// occurs to create a replacement [Page].
typedef LocationErrorPageBuilder = Page<Object?> Function(BuildContext context, {
  required Key key,
  required String name,
  required String restorationId,
  required Object error,
  StackTrace? stackTrace,
});
