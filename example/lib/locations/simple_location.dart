import 'package:flutter/cupertino.dart';
import 'package:k_router/k_router.dart';

import '../page_content_builder.dart';
import 'locations.dart';


// Inherit default constructors
final class SimpleLocation = BaseLocation<Object?> with _SimpleLocation;
base mixin _SimpleLocation<T> on BaseLocation<T> {
  @override
  Locations get discriminator => Locations.simple;

  @override
  Page<T> buildPage(BuildContext context, {
    required LocalKey key,
    required String name,
    required String restorationId,
    required Widget child,
  }) => CupertinoPage(
    key: key,
    name: name,
    restorationId: restorationId,
    title: title,
    child: child,
  );

  @override
  Widget build(BuildContext context) =>
    CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Page: $title | $uri'),
      ),
      child: SizedBox.expand(
        child: pageContentBuilder(context, this),
      ),
    );
}
