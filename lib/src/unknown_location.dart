import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'location.dart';
import 'location_base.dart';
import 'location_codec.dart';
import 'location_discriminator.dart';



/// Unknown location fallback.
///
/// Used when router encounters location data it has no codec available for.
final class UnknownLocation extends BaseLocation<Never> implements LocationWithStateEncoder<Never> {
  /// Create new [UnknownLocation].
  @internal
  UnknownLocation({
    required super.uri,
    super.title,
    Map<Object?, Object?>? state,
  }) : _state = state;

  /// Create new [UnknownLocation] from [LocationOptions].
  @internal
  UnknownLocation.fromOptions(LocationOptions options) : this(
    uri: options.uri,
    title: options.title,
    state: options.state
  );

  @override
  void applyOptions(LocationOptions options) {
    super.applyOptions(options);
    _state = options.state;
  }

  Map<Object?, Object?>? _state;

  @override
  LocationEncoded encodeState() => _state ?? const {};

  /// Raw discriminator integer.
  /// Visible to allow creating custom unknown location.
  static const LocationDiscriminator locationDiscriminator = _InternalLocationDiscriminator(-500);

  @override
  LocationDiscriminator get discriminator => locationDiscriminator;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: ListView(
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        children: [
          const Text('Failed to restore location, tap to pop'),
          Text('Name: $title'),
          Text('Uri: $uri'),
          Text('State: $_state'),
        ],
      ),
    ),
  );
}

class _InternalLocationDiscriminator implements LocationDiscriminator {
  const _InternalLocationDiscriminator(this.discriminator);

  @override
  final int discriminator;
}
