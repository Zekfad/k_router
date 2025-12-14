import 'package:meta/meta.dart';


// Very internal helper to for extracting type argument of location iif it's
// extended from base implementations.

/// @nodoc
@internal
mixin LocationPopType<T> {
  Type get _popType => T;
  bool _canPopWith(Object? value) => value is T?;
}

/// @nodoc
@internal
extension LocationPopTypeExtension<T> on LocationPopType<T> {
  /// @nodoc
  @internal
  Type get popType => _popType;

  /// @nodoc
  @internal
  bool canPopWith(Object? value) => _canPopWith(value);
}
