import 'dart:convert';

import 'package:meta/meta.dart';

import 'internal_locations.dart';
import 'location.dart';


/// Maps discriminator integer to location codec.
typedef LocationCodecMap = Map<int, LocationCodec<Object?>>;
/// Location in serializable format.
typedef LocationEncoded = Map<Object?, Object?>;
/// Common set of options used by every location.
typedef LocationOptions = ({
  int discriminator,
  Uri uri,
  String? title,
  LocationEncoded state,
});
/// Location factory constructor. __MUST__ always create new location from given
/// [options].
typedef LocationFactory<T> = Location<T> Function(LocationOptions options);
/// Location encoder function. Turns [Location] into serializable format.
typedef LocationStateEncoder<T> = LocationEncoded Function(Location<T> input);

/// {@template k_router_location_codec}
/// Basic location codec. Turns any configuration to unknown location.
/// Override this class to create custom codec for your specific location class.
/// {@endtemplate}
base class LocationCodec<T> extends Codec<Location<T>, LocationEncoded> {
  /// {@macro k_router_location_codec}
  const LocationCodec();

  /// Encode location's state into serializable format. By default returns empty
  /// map.
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  LocationEncoded encodeState(Location<T> input) => switch(input) {
    final LocationWithStateEncoder input => input.encodeState(),
    _ => const {},
  };

  /// Create new location from [options]. By default creates fallback unknown
  /// location.
  @factory
  Location<T> constructLocation(LocationOptions options) =>
    UnknownLocation.fromOptions(options);

  @override
  LocationEncoded encode(Location<T> input) => {
    'd': input.discriminator.discriminator,
    'u': input.uri.toString(),
    't': input.title,
    's': encodeState(input),
  };

  @override
  Location<T> decode(LocationEncoded encoded) => switch(encoded) {
    {
      'd': final int discriminator,
      'u': final String uri,
      't': final String? title,
      's': final LocationEncoded state,
    } => constructLocation((
      discriminator: discriminator,
      uri: Uri.parse(uri),
      title: title,
      state: state,
    )),
    _ => throw FormatException('Invalid format of location primitive state', encoded),
  };
  
  @override
  Converter<LocationEncoded, Location<T>> get decoder =>
    _FunctionConverter(decode);
  
  @override
  Converter<Location<T>, LocationEncoded> get encoder =>
    _FunctionConverter(encode);
}

class _FunctionConverter<S, T> extends Converter<S, T> {
  const _FunctionConverter(this._converter);

  // Guarded via [convert] method.
  // ignore: unsafe_variance
  final T Function(S input) _converter;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @override
  T convert(S input) => _converter(input);
}
