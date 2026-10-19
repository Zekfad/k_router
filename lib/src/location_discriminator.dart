import 'location_codec.dart';


/// Location discriminator interface.
///
/// [discriminator] must be a globally unique integer for mapping locations
/// to their codecs.
///
/// It's recommended to use enum with [LocationDiscriminatorEnum] instead of
/// directly implementing this interface.
abstract interface class LocationDiscriminator {
  /// Globally unique integer identifying location class.
  int get discriminator;
}

/// An implementation of [LocationDiscriminator] using [Enum].
///
/// Enum is recommended because state restoration is done across process
/// restart which requires data to be available at router initialization.
///
/// Use `values` with [LocationDiscriminatorCodecsMap.toLocationCodecMap] to
/// quickly turn enum with this mixin into a [LocationCodecMap].
mixin LocationDiscriminatorEnum on Enum implements LocationDiscriminator {
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @override
  int get discriminator => index;

  /// Associated with this [discriminator] location codec.
  LocationCodec<Object?> get codec;
}

/// Helper method for converting enum values into [LocationCodecMap].
extension LocationDiscriminatorCodecsMap on List<LocationDiscriminatorEnum> {
  /// Create [LocationCodecMap] from this list of enum values.
  LocationCodecMap toLocationCodecMap() => {
    for (final discriminator in this)
      discriminator.discriminator: discriminator.codec,
  };
}
