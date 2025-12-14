import 'package:flutter/cupertino.dart';
import 'package:k_router/k_router.dart';

import '../page_content_builder.dart';
import 'locations.dart';


final class SimpleShellLocation extends BaseShellLocation with LocationWithStateEncoder {
  SimpleShellLocation({ required super.uri, super.title, this.noTopHero = false, });
  SimpleShellLocation.fromOptions(super.options) :
    noTopHero = options.state['n']! as bool,
    super.fromOptions();

  final bool noTopHero;

  @override
  Locations get discriminator => Locations.simpleShell;

  @override
  LocationEncoded encodeState() => { 'n': noTopHero, };

  @override
  List<Location<Object?>> get children => [
    SimpleLocation(uri: Uri.parse('/simple_shell/inner/1'), title: 'Shell inner page'),
  ];

  @override
  Page<Object?> buildPage(BuildContext context, {
    required String restorationId,
    Widget? navigator,
  }) => CupertinoPage(
    key: ValueKey(this),
    restorationId: restorationId,
    name: uri.toString(),
    title: title,
    child: build(context, navigator: navigator),
  );

  @override
  Widget build(BuildContext context, {
    Widget? navigator,
  }) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: Text('Page: $uri | $title'),
      transitionBetweenRoutes: !noTopHero,
    ),
    child: Column(
      children: [
        pageContentBuilder(context, this),
        Expanded(
          child: navigator!,
        ),
      ],
    ),
  );
}
