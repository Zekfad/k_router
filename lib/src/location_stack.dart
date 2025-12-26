import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'location.dart';
import 'location_stack_item.dart';
import 'location_stack_items_list.dart';


@internal
final class LocationStack extends ChangeNotifier {
  @internal
  LocationStack({
    LocationStackItemsList? children,
    this.activeItem,
    this.parentItem,
  }) : items = children ?? LocationStackItemsList() {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'package:k_router/k_router.dart',
        className: 'LocationStack',
        object: this,
      );
    }
    items.stack = this;
    items.forEach(_registerItem);
  }

  factory LocationStack.initial(Location<Object?> location) {
    final item = LocationStackItem(
      location: location,
    );
    if (location case final LocationWithChildren<Object?> shell) {
      for (final child in shell.children) {
        item.children.pushLocation(child, false)
          .catchError(popErrorHandler).ignore();
      }
    }
    return LocationStack(
      children: LocationStackItemsList()..add(item),
      activeItem: item,
    );
  }

  static final Map<int, LocationStackItem> cachedItems = {};

  static void popErrorHandler(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('Pop of route resulted in an error: ${Error.safeToString(error)}');
      debugPrintStack(
        label: 'LocationStack.popErrorHandler',
        stackTrace: stackTrace,
      );
    }
  }

  final Map<LocationStackItem, VoidCallback> _itemListeners = {};
  final LocationStackItemsList items;
  LocationStackItem? activeItem;
  LocationStackItem? parentItem;

  LocationStack get leafActiveStack {
    var parentStack = this;
    var stack = this;
    while (stack.activeItem != null) {
      parentStack = stack;
      stack = stack.activeItem!.children;
    }
    return parentStack;
  }

  LocationStackItem get leafActiveItem {
    final stack = leafActiveStack;
    assert(
      stack.activeItem != null || stack.parentItem != null,
      'leaf item must exist'
    );
    return stack.activeItem ?? stack.parentItem!;
  }

  LocationStackItem? findPage(Page<Object?> page, { bool recursive = false, }) {
    final item = LocationStackItem.pageCache[page] ??
      items.firstWhereOrNull((element) => element.page == page);
    if (item != null) {
      return item;
    }
    if (!recursive) {
      return null;
    }
    for (final item in items) {
      final res = item.children.findPage(page, recursive: true);
      if (res != null) {
        return res;
      }
    }
    return null;
  }

  Future<T?> pushLocation<T>(Location<T> location, [ bool notify = true, ]) {
    final newItem = LocationStackItem(
      location: location,
    );
    items.add(newItem);
    activeItem = newItem;
    _cachedActiveItemIndex = items.length - 1;
    if (location case final LocationWithChildren<Object?> shell) {
      for (final child in shell.children) {
        newItem.children.pushLocation(child, notify)
          .catchError(popErrorHandler).ignore();
      }
      if (location case final MultiLocation<Object?> multiLocation) {
        newItem.children.selectChild(multiLocation.activeIndex, notify);
      }
    }
    _registerItem(newItem);
    if (notify) {
      notifyListeners();
    }
    return newItem.popCompleter.future.then(
      (value) => value is T? ? value : throw ArgumentError.value(
        value,
        'result',
        'Location popped with invalid type of value: '
        'expected $T or null, got: ${value.runtimeType}',
      ),
    );
  }

  void _registerItem(LocationStackItem item) {
    cachedItems[item.id] = item;
    if (!_itemListeners.containsKey(item)) {
      item.location.addListener(
        _itemListeners[item] = () => didUpdateItem(item),
      );
    }
  }

  int? _cachedActiveItemIndex;
  int get activeItemIndex {
    assert(items.isNotEmpty, 'Multi location has no children');
    if (_cachedActiveItemIndex case final index?) {
      assert(activeItem == items.elementAt(index), 'invalid cached index');
      return index;
    }
    for (final (index, item) in items.indexed) {
      if (item == activeItem) {
        return _cachedActiveItemIndex = index;
      }
    }
    throw StateError('Cannot find active item index');
  }

  bool selectChild(int index, [ bool notify = true, ]) {
    if (index < 0 || index >= items.length) {
      return false;
    }
    if (index == _cachedActiveItemIndex) {
      assert(activeItem == items.elementAt(index), 'invalid cached index');
      return true;
    }
    final newActiveItem = items.elementAt(index);
    assert(
      activeItem != newActiveItem || _cachedActiveItemIndex == null,
      'same item can only be retrieved due to removal which should\'ve made '
      'cached index null',
    );
    _cachedActiveItemIndex = index;
    if (activeItem == newActiveItem) {
      return true;
    }
    activeItem = newActiveItem;
    if (parentItem?.location case final MultiLocation<Object?> location) {
      location.activeIndex = index;
    }
    if (notify) {
      notifyListeners();
    }
    return true;
  }

  int indexOf(LocationStackItem item) {
    for (final (index, child) in items.indexed) {
      if (identical(item, child)) {
        return index;
      }
    }
    return -1;
  }

  void didUpdateItem(LocationStackItem item) {
    // force rebuild of page from the scratch
    if (item.location case final MultiLocation<Object?> location) {
      item.children.selectChild(location.activeIndex);
    }
    item.reset();
    notifyListeners();
  }

  /// Removes item and it's linked data nodes.
  /// 
  /// * item is removed from [cachedItems]
  /// * item in unlinked from [items]
  /// * removed listeners for this item's location updates
  /// * item's location is disposed
  /// * item's cached page and encoded state removed
  /// * item's completer attempted to complete with [result]
  /// * item's children stack is disposed
  /// * if [notify] is true listeners are notified
  void didRemoveItem(LocationStackItem item, {
    bool notify = true,
    FutureOr<Object?>? result,
  }) {
    cachedItems.remove(item.id);
    _cachedActiveItemIndex = null;
    if (activeItem == (item..unlink())) {
      activeItem = items.lastOrNull;
      if (activeItem != null) {
        _cachedActiveItemIndex = items.length - 1;
      }
    }
    (item..reset()).location
      ..removeListener(_itemListeners.remove(item)!)
      ..dispose();
    if (!item.popCompleter.isCompleted) {
      item.popCompleter.complete(result);
    }
    item.children.dispose();
    if (notify) {
      notifyListeners();
    }
  }

  /// Silently detaches item from the stack.
  /// 
  /// This works the same as removing but:
  /// * location is not disposed
  /// * completer is not attempted to complete with null
  /// * item children are not disposed
  /// * item retain cached page and encoded state
  /// * item retained in [cachedItems]
  void detachItem(LocationStackItem item) {
    _cachedActiveItemIndex = null;
    if (activeItem == (item..unlink())) {
      activeItem = items.lastOrNull;
      if (activeItem != null) {
        _cachedActiveItemIndex = items.length - 1;
      }
    }
    item.location.removeListener(_itemListeners.remove(item)!);
  }

  void triggerUpdate() => notifyListeners();

  @override
  void dispose() {
    if (!kReleaseMode) {
      Timeline.startSync('LocationStack#dispose');
    }
    // copy to prevent concurrent modification
    for (final child in items.toList(growable: false)) {
      didRemoveItem(child, notify: false);
    }
    super.dispose();
    if (!kReleaseMode) {
      Timeline.finishSync();
    }
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(
        object: this,
      );
    }
  }
}
