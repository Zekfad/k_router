import 'package:flutter/cupertino.dart';


class CupertinoSheetPage<T> extends CupertinoPage<T> {
  const CupertinoSheetPage({
    required super.child,
    this.enableDrag = true,
    super.maintainState,
    super.title,
    super.fullscreenDialog,
    super.canPop,
    super.onPopInvoked,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final bool enableDrag;

  @override
  Route<T> createRoute(BuildContext context) {
    // this is needed because route object's page will be updated as part of
    // router operation
    late final CupertinoSheetRoute<T> route;
    return route = CupertinoSheetRoute(
      settings: this,
      builder: (context) => (route.settings as CupertinoPage<T>).child,
      enableDrag: enableDrag,
    );
  }
}
