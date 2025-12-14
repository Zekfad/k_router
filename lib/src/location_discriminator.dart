import 'location_codec.dart';


/// Location discriminator interface.
/// 
/// [discriminator] must be a globally unique integer for mapping locations
/// to their codecs.
/// 
/// This is made on top of enum because state restoration is done across process
/// restart which means any data must be available from the start.
/// 
/// Use `values` with [LocationDiscriminatorCodecsMap.toLocationCodecMap] to
/// quickly turn enum with with mixin into a [LocationCodecMap].
mixin LocationDiscriminator on Enum {
  /// Globally unique integer identifying location class.
  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  int get discriminator => index;

  /// Associated with this [discriminator] location codec.
  LocationCodec<Object?> get codec;
}

/// Helper method for converting enum values into [LocationCodecMap].
extension LocationDiscriminatorCodecsMap on List<LocationDiscriminator> {
  /// Create [LocationCodecMap] from this list of enum values.
  LocationCodecMap toLocationCodecMap() => {
    for (final discriminator in this)
      discriminator.discriminator: discriminator.codec,
  };
}
