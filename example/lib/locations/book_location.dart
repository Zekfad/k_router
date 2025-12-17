import 'package:flutter/cupertino.dart';
import 'package:k_router/k_router.dart';

import '../cupertino_sheet_page.dart';
import '../page_content_builder.dart';
import 'locations.dart';


final class BookLocation extends BaseLocation<String> with LocationWithStateEncoder {
  BookLocation(this.id, [ String title = 'Book', ])
    : super(uri: Uri.parse('/book/$id/'), title: title);

  BookLocation.fromOptions(super.options) :
    id = options.state['id']! as int,
    super.fromOptions();

  final int id;

  @override
  Locations get discriminator => Locations.book;

  @override
  LocationEncoded encodeState() => { 'id': id, };

  @override
  Page<String> buildPage(BuildContext context, {
    required LocalKey key,
    required String name,
    required String restorationId,
    required Widget child,
  }) => CupertinoSheetPage(
    key: key,
    name: name,
    restorationId: restorationId,
    title: title,
    child: child,
    enableDrag: true,
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
