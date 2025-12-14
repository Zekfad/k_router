import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'location.dart';
import 'location_base.dart';
import 'location_codec.dart';
import 'location_discriminator.dart';
import 'location_function_codec.dart';


@internal
enum InternalLocations with LocationDiscriminator {
  unknown(LocationFunctionCodec(UnknownLocation.fromOptions)),
  ;

  const InternalLocations(this.codec);

  @override
  final LocationCodec<Object?> codec;

  @pragma('vm:prefer-inline')
  @pragma('wasm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @override
  int get discriminator => -(500 + index);
}

@internal
final class UnknownLocation extends BaseLocation<Never> with LocationWithStateEncoder {
  @internal
  UnknownLocation({
    required super.uri,
    super.title,
    this.state,
  });

  @internal
  UnknownLocation.fromOptions(LocationOptions options) : this(
    uri: options.uri,
    title: options.title,
    state: options.state
  );

  final Map<Object?, Object?>? state;

  @override
  LocationEncoded encodeState() => state ?? const {};

  @override
  InternalLocations get discriminator => InternalLocations.unknown;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Unknown location'),
    ),
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Name: $title'),
        Text('Uri: $uri'),
        Text('State: $state'),
      ],
    ),
  );
}
