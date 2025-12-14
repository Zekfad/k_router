import 'package:meta/meta.dart';

import 'location.dart';


/// Deep link handler function.
/// This function is always a synchronous. If your processing of [uri] requires
/// async computation consider using:
/// * [DeepLinkResult.ignore] and processing your link with later side effects.
/// * [DeepLinkResult.push] with location that processes your link and show some
///   loading animation while doing it.
typedef DeepLinkHandler = DeepLinkResult Function(Uri uri);

/// Result of processing deep link.
sealed class DeepLinkResult {
  /// Ignore deep link. You can use this result if your handler creates
  /// side-effects and doesn't need to update navigation stack.
  const factory DeepLinkResult.ignore() = DeepLinkIgnore._;
  /// Push new location next to current leaf node.
  /// Note that shell and multi locations are never leaf nodes (and multi
  /// location always contains at least one shell), which means that if you're
  /// on a shell location this mode will add location into inner navigator.
  const factory DeepLinkResult.push(Location<Object?> location) = DeepLinkPush._;
  /// Push new location to root navigator.
  const factory DeepLinkResult.pushToRoot(Location<Object?> location) = DeepLinkPushToRoot._;
  /// Replace whole navigation stack with a single new root location.
  const factory DeepLinkResult.replaceStack(Location<Object?> location) = DeepLinkReplaceStack._;
}

/// @nodoc
@internal
final class DeepLinkIgnore implements DeepLinkResult {
  const DeepLinkIgnore._();
}

/// @nodoc
@internal
final class DeepLinkPush implements DeepLinkResult {
  const DeepLinkPush._(this.location);

  final Location<Object?> location; 
}

/// @nodoc
@internal
final class DeepLinkPushToRoot implements DeepLinkResult {
  const DeepLinkPushToRoot._(this.location);

  final Location<Object?> location; 
}

/// @nodoc
@internal
final class DeepLinkReplaceStack implements DeepLinkResult {
  const DeepLinkReplaceStack._(this.location);

  final Location<Object?> location; 
}
