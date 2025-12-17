import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:k_router/k_router.dart';

import 'locations.dart';


// Inherit default constructors
final class SimpleMultiLocation = BaseMultiLocation<Object?> with _SimpleMultiLocation;
base mixin _SimpleMultiLocation<T> on BaseMultiLocation<T> {
  @override
  Locations get discriminator => Locations.simpleMulti;

  @override
  List<ShellLocation<Object?>> get children => [
    SimpleShellLocation(uri: Uri.parse('/sub_shell/1'), title: 'Sub shell 1', noTopHero: true),
    SimpleShellLocation(uri: Uri.parse('/sub_shell/2'), title: 'Sub shell 2', noTopHero: true),
  ];

  @override
  Page<T> buildPage(BuildContext context, {
    required LocalKey key,
    required String name,
    required String restorationId,
    required Widget child,
    int? activeIndex,
  }) => CupertinoPage(
    key: key,
    name: name,
    restorationId: restorationId,
    title: title,
    child: child,
  );

  @override
  Widget build(BuildContext context, {
    List<Widget>? children,
    int? activeIndex,
  }) =>
    CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Page: $title | $uri | $activeIndex'),
      ),
      child: Column(
        children: [
          // page(context, this),
          Expanded(
            child: Row(
              children: [
                for (final (i, child) in children!.indexed)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Material(
                        color: Colors.transparent,
                        elevation: i == activeIndex ? 16 : 0,
                        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          child: child,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
}
