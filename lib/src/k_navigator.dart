import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'current_location.dart';
import 'k_router_delegate.dart';
import 'location.dart';
import 'location_pop_type.dart';
import 'location_stack.dart';
import 'location_stack_item.dart';


@internal
const kNavigatorFactory = KNavigator._;

/// K Router navigator provides location stack controls to descendants.
class KNavigator extends InheritedWidget {
  /// @nodoc
  KNavigator._new({
    required KRouterDelegate delegate,
    required LocationStack stack,
    required this.navigatorKey,
    required String restorationScopeId,
    required GlobalKey<_KNavigatorState> kNavigatorKey,
    bool createHeroController = true,
  }) :
    _delegate = delegate,
    _stack = stack,
    _restorationScopeId = restorationScopeId,
    _kNavigatorKey = kNavigatorKey,
    super(
      child: _KNavigator(
        key: kNavigatorKey,
        delegate: delegate,
        stack: stack,
        navigatorKey: navigatorKey,
        restorationScopeId: restorationScopeId,
        createHeroController: createHeroController,
      ),
    );

  /// @nodoc
  factory KNavigator._({
    required KRouterDelegate delegate,
    required LocationStack stack,
    required GlobalKey<NavigatorState> navigatorKey,
    required String restorationScopeId,
    bool createHeroController = true,
  }) => KNavigator._new(
    delegate: delegate,
    stack: stack,
    navigatorKey: navigatorKey,
    restorationScopeId: restorationScopeId,
    createHeroController: createHeroController,
    kNavigatorKey: GlobalKey(debugLabel: '_kNavigator#$restorationScopeId'),
  );

  final GlobalKey<_KNavigatorState> _kNavigatorKey;
  /// Raw navigator key.
  ///
  /// If router is used correctly you dont need it.
  final GlobalKey<NavigatorState> navigatorKey;
  final KRouterDelegate _delegate;
  final LocationStack _stack;
  final String _restorationScopeId;

  /// Emits null values when managed location stack changes.
  Stream<void> get changes => _kNavigatorKey.currentState!._changes;

  /// Pushes new location to this navigator.
  @awaitNotRequired
  Future<T?> pushLocation<T>(Location<T> location) =>
    _stack.pushLocation(location);

  /// Removes current location from this navigator and pushes new location
  /// in place of it.
  @awaitNotRequired
  Future<T?> replaceLocation<T>(Location<T> location) {
    final future = _stack.pushLocation(location);
    final removed = _stack.activeItem!.previous!.remove();
    assert(removed, 'failed to remove previous item during replace');
    return future;
  }

  /// Checks if navigator can pop current location.
  bool canPop() =>
    navigatorKey.currentState!.canPop();

  /// Tries to pop current location of this navigator from the navigation stack.
  Future<bool> maybePop<T extends Object>([ T? result, ]) {
    _checkPopType(result);
    return navigatorKey.currentState!.maybePop(result);
  }

  /// Forcefully pops current location of this navigator location disregarding
  /// [Page.canPop].
  ///
  /// You must be careful when using this method because it can easily lead to
  /// irrecoverable invalid state of router.
  void forcePop<T extends Object>([ T? result, ]) {
    _checkPopType(result);
    return navigatorKey.currentState!.pop(result);
  }

  void _checkPopType(Object? result) {
    // this check is only valid for locations extended from base location
    if (_stack.activeItem?.location case
      final LocationPopType<Object?> activeLocation
      when !activeLocation.canPopWith(result)
    ) {
      throw ArgumentError.value(
        result,
        'result',
        'Location popped with invalid type of value: '
        'expected ${activeLocation.popType} or null, got ${result.runtimeType}',
      );
    }
  }

  /// Brings to top existing location on a given index.
  void bringToTopLocationAt(int index) {
    final result = _stack.selectChild(index);
    assert(result, 'Cannot select requested child: index is out of bounds');
  }

  /// Retrieves active location of this navigator.
  Location<Object?>? get activeLocation {
    if (_stack.items.isEmpty) {
      return null;
    }
    // active item is always present for non empty stacks
    return _stack.activeItem!.location;
  }

  /// Retrieves deepest leaf active location of this navigator.
  Location<Object?>? get leafActiveLocation {
    if (_stack.items.isEmpty) {
      return null;
    }
    // active item is always present for non empty stacks
    return _stack.leafActiveItem.location;
  }

  /// Retrieves current locations stack of this navigator.
  ///
  /// Returned list is ordered by push calls which means [activeLocation] is
  /// __NOT__ always the last item.
  ///
  /// This getter is relatively expensive (required full linked list iteration)
  /// and returns snapshot of current stack.
  /// You're free to modify returned list, it wont affect routing.
  List<Location<Object?>> get locationsStack =>
    _stack.items.map((e) => e.location).toList();

  /// The first [Location] in stack satisfying [test], or `null` if there are
  /// none.
  Location<Object?>? firstLocationWhereOrNull(
    bool Function(Location<Object?> location) test
  ) => _stack.items.firstWhereOrNull(
    (element) => test(element.location),
  )?.location;

  /// The first [Location] whose value and index satisfies [test].
  ///
  /// Returns `null` if there are no element and index satisfying [test].
  Location<Object?>? firstLocationWhereIndexedOrNull(
    bool Function(int index, Location<Object?> location) test
  ) => _stack.items.firstWhereIndexedOrNull(
    (index, element) => test(index, element.location),
  )?.location;

  /// Returns stack path for the [location] if it is mounted.
  String? stackPathOf<T>(Location<T> location) {
    var item = LocationStackItem.locationCache[location];
    String? path;
    while (item != null) {
      if (path == null) {
        path = item.index.toString();
      } else {
        path = '${item.index}/$path';
      }
      item = item.stack.parentItem;
    }
    assert(path != null, 'Unmounted location.');
    return path;
  }

  /// Returns hero prefix for the [location] if it is mounted.
  ///
  /// It will end with `/*` for most of location except for shell locations that
  /// are direct descendants of multi location for which it will end with slash
  /// plus corresponding index of shell.
  ///
  /// If you want to animate hero to a specific shell in multi location, replace
  /// `*` with target shell index.
  ///
  /// Beware that Flutter allows animating hero from outer navigator to inner
  /// if it is part of the top-most route in that nested Navigator and if that
  /// route is also a PageRoute.
  ///
  /// If you expect your hero to be present twice (as top location and inside of
  /// nested navigator consider disabling [allowCrossBorders], that will make
  /// returned prefix unique to [location]'s level of nesting).
  String? heroPrefixFor<T>(Location<T> location, { bool allowCrossBorders = true, }) {
    var item = LocationStackItem.locationCache[location];
    assert(item != null, 'Unmounted location.');
    if (allowCrossBorders) {
      if (item == null) {
        return null;
      }
      final parent = item.stack.parentItem;
        return parent?.location is! MultiLocation
          ? '*'
        : item.index.toString();
    }
    String? path;
    while (item != null) {
      final parent = item.stack.parentItem;
      if (path == null) {
        path = parent?.location is! MultiLocation ? '*' : item.index.toString();
      } else {
        path = '${item.index}/$path';
      }
      item = parent;
    }
    return path;
  }

  /// Checks whether [context] is part of leaf active location of root navigator.
  static bool isContextActive(BuildContext context) =>
    of(context)._delegate.currentConfiguration.leafActiveItem.location == CurrentLocation.of(context);

  /// Try to get [BuildContext] of shell inside of [location].
  static BuildContext? getContextOfShell(ShellLocation<Object?> location) {
    final item = LocationStackItem.locationCache[location];
    assert(item != null, 'Unmounted location.');
    // activeItem is always present, because it's impossible to create item for
    // multi location with no children
    final context = item?.shellNavigatorKey?.currentContext;
    if (context == null) {
      return null;
    }
    return (context.mounted) ? context : null;
  }

  /// Try to get [BuildContext] of active shell inside of [location].
  static BuildContext? getContextOfActiveShell(MultiLocation<Object?> location) {
    final item = LocationStackItem.locationCache[location];
    assert(item != null, 'Unmounted location.');
    // activeItem is always present, because it's impossible to create item for
    // multi location with no children
    return item?.children.activeItem!.shellNavigatorKey?.currentContext;
  }

  /// Try to get [KNavigator] from this [context].
  static KNavigator? maybeOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<KNavigator>();

  /// Try to get [KNavigator] from context of shell inside of [location].
  static KNavigator? maybeOfShell(ShellLocation<Object?> location) {
    final item = LocationStackItem.locationCache[location];
    assert(item != null, 'Unmounted location.');
    return item?.shellNavigator;
  }

  /// Try to get [KNavigator] from context of active shell inside of [location].
  static KNavigator? maybeOfActiveShell(MultiLocation<Object?> location) {
    final item = LocationStackItem.locationCache[location];
    assert(item != null, 'Unmounted location.');
    return item?.children.activeItem!.shellNavigator;
  }

  /// Require [KNavigator] from context of shell inside of [location].
  static KNavigator ofShell(ShellLocation<Object?> location) {
    final result = maybeOfShell(location);
    assert(result != null, 'No KNavigator found in shell context');
    return result!;
  }

  /// Require [KNavigator] from context of active shell inside of [location].
  static KNavigator ofActiveShell(MultiLocation<Object?> location) {
    final result = maybeOfActiveShell(location);
    assert(result != null, 'No KNavigator found in active shell context');
    return result!;
  }

  /// Require [KNavigator] from this [context].
  static KNavigator of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No KNavigator found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant KNavigator oldWidget) =>
    !identical(oldWidget._stack, _stack) ||
    !identical(oldWidget.navigatorKey, navigatorKey) ||
    oldWidget._restorationScopeId != _restorationScopeId;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('navigatorKey', navigatorKey))
      ..add(DiagnosticsProperty('activeLocation', activeLocation))
      ..add(DiagnosticsProperty('leafActiveLocation', leafActiveLocation))
      ..add(IterableProperty('locationsStack', locationsStack))
      ..add(DiagnosticsProperty('changes', changes))
      ..add(DiagnosticsProperty('_stack', _stack))
      ..add(StringProperty('_restorationScopeId', _restorationScopeId));
  }
}

class _KNavigator extends StatefulWidget {
  const _KNavigator({
    required this.delegate,
    required this.stack,
    required this.navigatorKey,
    required this.restorationScopeId,
    required this.createHeroController,
    super.key,
  });

  final KRouterDelegate delegate;
  final LocationStack stack;
  final GlobalKey<NavigatorState> navigatorKey;
  final String restorationScopeId;
  final bool createHeroController;

  @override
  State<_KNavigator> createState() => _KNavigatorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('restorationScopeId', restorationScopeId))
      ..add(DiagnosticsProperty('navigatorKey', navigatorKey))
      ..add(DiagnosticsProperty('delegate', delegate))
      ..add(DiagnosticsProperty('stack', stack))
      ..add(FlagProperty('createHeroController', value: createHeroController, ifTrue: 'create', ifFalse: 'inherit'));
  }
}

class _KNavigatorState extends State<_KNavigator> {
  late final List<NavigatorObserver> _observers = [
    _KNavigatorObserver(
      didPopRoute: _onDidPopRoute,
    ),
  ];
  HeroController? _heroController;

  late final _changesController = StreamController<void>.broadcast();
  Stream<void> get _changes => _changesController.stream;

  @override
  void initState() {
    if (widget.createHeroController) {
      _heroController = HeroController();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _KNavigator oldWidget) {
    if (oldWidget.createHeroController && !widget.createHeroController) {
      _heroController!.dispose();
    }
    if (!oldWidget.createHeroController && widget.createHeroController) {
      _heroController = HeroController();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void reassemble() {
    // trigger rebuild for all pages during hot reload
    for (final item in widget.stack.items) {
      item.reset();
    }
    widget.stack.triggerUpdate();
    super.reassemble();
  }

  @override
  void dispose() {
    _heroController?.dispose();
    _observers.clear();
    _changesController.close().ignore();
    super.dispose();
  }


  void _onDidRemovePage(Page<Object?> page) {
    // called when router finishes pop animation and page is gone
  }

  void _onDidPopRoute(Route<Object?> route) {
    // called right after pop is confirmed
    if (route.settings case final Page<Object?> page) {
      final item = widget.stack.findPage(page, recursive: true);
      if (item == null) {
        return;
      }
      if (item.remove(route.popped)) {
        item
          ..shellNavigatorKey = null
          ..shellNavigator = null;
      } else {
        // add back last item to prevent black screen
        widget.stack.triggerUpdate();
      }
    }
  }

  Page<Object?> _buildPage(BuildContext context, int index, LocationStackItem item) =>
    item.page ??= switch (item.location) {
      final ShellLocation<Object?> shell => shell.buildPage(
        context,
        key: ValueKey(shell),
        name: shell.uri.toString(),
        restorationId: '$index#${shell.discriminator.discriminator}',
        child: currentLocationFactory(
          key: ValueKey(shell),
          location: shell,
          child: shell.build(
            context,
            navigator: item.shellNavigator = kNavigatorFactory(
              delegate: widget.delegate,
              stack: item.children,
              navigatorKey: item.shellNavigatorKey
                ??= GlobalKey(debugLabel: 'shell nested navigator ${widget.restorationScopeId}/$index'),
              restorationScopeId: '${widget.restorationScopeId}/$index',
            ),
          ),
        ),
      ),
      final MultiLocation<Object?> location => location.buildPage(
        context,
        key: ValueKey(location),
        name: location.uri.toString(),
        restorationId: '$index#${location.discriminator.discriminator}',
        child: currentLocationFactory(
          key: ValueKey(location),
          location: location,
          child: location.build(
            context,
            children: [
              for (final (childIndex, childItem) in item.children.items.indexed)
                RestorationScope(
                  restorationId: '${widget.restorationScopeId}/$index/$childIndex',
                  // propagate focus changes to router
                  child: _GroupFocusListener(
                    onFocus: () => item.children.selectChild(childIndex),
                    child: Listener(
                      onPointerDown: (event) => item.children.selectChild(childIndex),
                      child: _StackListener(
                        delegate: widget.delegate,
                        stack: item.children,
                        onChange: () {
                          // trigger rebuild of shell when children changes
                          item.reset();
                          item.stack.triggerUpdate();
                        },
                        child: currentLocationFactory(
                          key: ValueKey(childItem.location),
                          location: childItem.location,
                          child: (childItem.location as ShellLocation<Object?>).build(
                            context,
                            navigator: childItem.shellNavigator = kNavigatorFactory(
                              delegate: widget.delegate,
                              stack: childItem.children,
                              navigatorKey: childItem.shellNavigatorKey
                                ??= GlobalKey(debugLabel: 'multi nested navigator ${widget.restorationScopeId}/$index/$childIndex'),
                              restorationScopeId: '${widget.restorationScopeId}/$index/$childIndex',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      final location => location.buildPage(
        context,
        key: ValueKey(location),
        name: location.uri.toString(),
        restorationId: '$index#${location.discriminator.discriminator}',
        child: currentLocationFactory(
          key: ValueKey(location),
          location: location,
          child: location.build(context),
        ),
      ),
    };

  @override
  Widget build(BuildContext context) {
    final child = _StackListener(
      delegate: widget.delegate,
      stack: widget.stack,
      onChange: () {
        if (_changesController.hasListener) {
          _changesController.add(null);
        }
      },
      builder: (context) {
        if (widget.stack.items.isEmpty) {
          return const SizedBox.expand();
        }
        final List<Page<Object?>> pages;
        assert(widget.stack.activeItem != null, 'no active item');
        if (widget.stack.activeItem case final active?) {
          pages = [];
          late Page<Object?> activePage;
          for (final (index, item) in widget.stack.items.indexed) {
            final page = _buildPage(context, index, item);
            if (item == active) {
              activePage = page;
            } else {
              pages.add(page);
            }
          }
          pages.add(activePage);
        } else {
          pages = <Page<Object?>>[
            for (final (index, item) in widget.stack.items.indexed)
              _buildPage(context, index, item)
          ];
        }
        return Navigator(
          key: widget.navigatorKey,
          restorationScopeId: widget.restorationScopeId,
          pages: pages,
          onDidRemovePage: _onDidRemovePage,
          observers: _observers,
        );
      },
    );
    if (_heroController case final controller?) {
      return HeroControllerScope(
        controller: controller,
        child: child,
      );
    }
    return child;
  }
}

class _KNavigatorObserver extends NavigatorObserver {
  _KNavigatorObserver({
    required this.didPopRoute,
  });

  void Function(Route<Object?> route) didPopRoute;

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) {
    didPopRoute(route);
  }
}

class _StackListener extends StatefulWidget {
  const _StackListener({
    required this.delegate,
    required this.stack,
    this.onChange,
    this.builder,
    this.child,
  }) : assert((child == null) != (builder == null), 'builder or child must be specified');

  final KRouterDelegate delegate;
  final LocationStack stack;
  final VoidCallback? onChange;
  final WidgetBuilder? builder;
  final Widget? child;

  @override
  State<_StackListener> createState() => _StackListenerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty.has('onChange', onChange))
      ..add(ObjectFlagProperty.has('builder', builder))
      ..add(DiagnosticsProperty('delegate', delegate))
      ..add(DiagnosticsProperty('stack', stack));
  }
}

class _StackListenerState extends State<_StackListener> {
  @override
  void initState() {
    super.initState();
    widget.stack.addListener(_didUpdateStack);
  }

  @override
  void didUpdateWidget(covariant _StackListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stack != oldWidget.stack) {
      oldWidget.stack.removeListener(_didUpdateStack);
      widget.stack.addListener(_didUpdateStack);
    }
  }

  @override
  void dispose() {
    widget.stack.removeListener(_didUpdateStack);
    super.dispose();
  }

  void _didUpdateStack() {
    if (!mounted) {
      return;
    }
    setState(() {
      // any stack update should be propagated back to router to update Uri
      // and commit restoration data
      widget.delegate.triggerUpdate();
    });
    widget.onChange?.call();
  }

  @override
  Widget build(BuildContext context) =>
    widget.child ?? widget.builder!(context);
}

class _GroupFocusListener extends StatefulWidget {
  const _GroupFocusListener({
    required this.child,
    this.onFocus,
  });

  final Widget child;
  final VoidCallback? onFocus;

  @override
  State<_GroupFocusListener> createState() => _GroupFocusListenerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty.has('onFocus', onFocus));
  }
}

class _GroupFocusListenerState extends State<_GroupFocusListener> {
  FocusNode? focusNode;
  bool _focused = false;

  void setFocusNode(FocusNode? value) {
    focusNode?.removeListener(onFocusNodeChange);
    focusNode = value;
    focusNode?.addListener(onFocusNodeChange);
    onFocusNodeChange();
  }

  void onFocusNodeChange() {
    if (!mounted) {
      return;
    }
    final hasFocus = focusNode?.hasFocus ?? false;
    if (!_focused && hasFocus) {
      widget.onFocus?.call();
    }
    _focused = hasFocus;
  }

  @override
  void dispose() {
    focusNode?.removeListener(onFocusNodeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusTraversalGroup(
    onFocusNodeCreated: setFocusNode,
    child: widget.child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('focusNode', focusNode));
  }
}
