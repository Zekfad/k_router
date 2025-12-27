import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'k_navigator.dart';
import 'location.dart';
import 'location_stack.dart';
import 'location_stack_items_list.dart';


@internal
final class LocationStackItem extends LinkedListEntry<LocationStackItem> {
  @internal
  LocationStackItem({
    required this.location,
    LocationStack? children,
  }) : children = children ?? LocationStack(), id = globalId++  {
    locationCache[location] = this;
    this.children.parentItem = this;
    assert(
      location is! LocationWithChildren ||
      (location as LocationWithChildren).children.isNotEmpty,
      'Multi or shell location has no children',
    );
  }

  static final locationCache = Expando<LocationStackItem>('Location LocationStackItem cache');
  static final pageCache = Expando<LocationStackItem>('Page LocationStackItem cache');
  static int globalId = 0;

  final Location<Object?> location;
  final Completer<Object?> popCompleter = Completer();
  final int id;
  LocationStack children;

  /// Cached page object
  Page<Object?>? _page;
  /// Cached page object
  Page<Object?>? get page => _page;

  set page(Page<Object?>? value) {
    if (!identical(_page, value)) {
      if (_page case final oldPage?) {
        pageCache[oldPage] = null;
      }
      if (value != null) {
        pageCache[value] = this;
      }
      _page = value;
    }
  }
  /// Cached encoded location
  Map<Object?, Object?>? encoded;
  GlobalKey<NavigatorState>? shellNavigatorKey;
  KNavigator? shellNavigator;

  @override
  LocationStackItemsList? get list => super.list as LocationStackItemsList?;

  LocationStack get stack => list!.stack;
  int get index => stack.indexOf(this);

  bool remove([ FutureOr<Object?>? result, ]) {
    assert(super.list != null, 'Item is not part of any stack');
    LocationStackItem? itemToRemove = this;
    while (
      itemToRemove?.list!.length == 1 || (
        itemToRemove?.location is ShellLocation &&
        itemToRemove?.stack.parentItem?.location is MultiLocation
      )
    ) {
      // if this is the last item
      // or shell inside of multi location,
      // we have to remove parent
      itemToRemove = itemToRemove!.stack.parentItem;
    }
    // assert(itemToRemove != null, 'cannot pop the last page of router');
    if (itemToRemove == null) {
      return false;
    }
    itemToRemove.stack.didRemoveItem(
      itemToRemove,
      notify: true,
      result: result,
    );
    return true;
  }

  void reset() {
    page = null;
    encoded = null;
  }
}
