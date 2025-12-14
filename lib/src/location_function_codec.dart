import 'location.dart';
import 'location_codec.dart';


/// {@template k_router_location_function_codec}
/// Location codec based on a serialize and deserialize functions.
/// 
/// You can use constructor and mix in [LocationWithStateEncoder] to location
/// for a more convenient usage.
/// {@endtemplate}
final class LocationFunctionCodec<T> extends LocationCodec<T> {
  /// {@macro k_router_location_function_codec}
  const LocationFunctionCodec(this._factory, [ this._stateEncoder, ]);

  final LocationFactory<T> _factory;
  // Guarded via [encodeState].
  // ignore: unsafe_variance
  final LocationStateEncoder<T>? _stateEncoder;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @override
  Map<Object?, Object?> encodeState(Location<T> input) =>
    _stateEncoder?.call(input) ?? super.encodeState(input);
  
  @override
  Location<T> constructLocation(LocationOptions options) =>
    _factory(options);
}
