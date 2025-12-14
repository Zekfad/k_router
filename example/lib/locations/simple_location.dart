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
    required String restorationId,
  }) => CupertinoPage(
    key: ValueKey(this),
    restorationId: restorationId,
    name: uri.toString(),
    title: title,
    child: build(context),
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
