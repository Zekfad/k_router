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
    int? id,
  }) : children = children ?? LocationStack(), id = id ?? globalId++ {
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

  /// Attempts to remove this item from associated navigation [stack].
  /// 
  /// If this is the last route in [stack] parent item is removed.
  /// This means that removing last item inside of shell location will remove
  /// shell itself.
  /// 
  /// Also removing shell that is a direct child of multi location causes parent
  /// (multi location) to be removed.
  /// 
  /// This is needed to prevent occurrence of empty multi or shell locations.
  /// 
  /// When ancestor item is removed instead of current [result] is passed to it
  /// and current route is completed with `null`.
  /// 
  /// Since you cannot push initial location for multi or shell location this
  /// makes sense.
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
