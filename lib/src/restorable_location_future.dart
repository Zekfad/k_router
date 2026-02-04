/// @docImport 'location.dart';
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'k_navigator.dart';


/// When a [State] object wants access to the return value of a [Location]
/// object it has pushed onto the [KNavigator], a [RestorableLocationFuture]
/// ensures that it will also have access to that value after state restoration.
/// 
/// To show a new location on the navigator defined by the [navigatorFinder],
/// call [present], which will invoke the [onPresent] callback. The [onPresent]
/// callback must add a new location to the navigator provided to it.
/// When the newly added location completes, the [onComplete] callback executes.
/// It is given the return value of the location, which may be `null`.
/// 
/// If the property is restored to a state in which [present] had been called on
/// it, but the location has not completed yet, the [RestorableLocationFuture]
/// will obtain the restored location object from the navigator again and call
/// [onComplete] once it completes.
/// 
/// The [RestorableLocationFuture] can only keep track of one active location.
/// When [present] has been called to add a location, it may only be called
/// again after the previously added location has completed.
@optionalTypeArgs
final class RestorableLocationFuture<T> extends RestorableProperty<int?> {
  /// Creates a [RestorableLocationFuture].
  RestorableLocationFuture({
    required this.onPresent,
    this.navigatorFinder = _defaultNavigatorFinder,
    this.onComplete,
  });

  static KNavigator _defaultNavigatorFinder(BuildContext context) => KNavigator.of(context);

  /// A callback that given the [BuildContext] of the [State] object to which
  /// this property is registered returns the [KNavigator] to which the location
  /// instantiated in [onPresent] is added.
  final KNavigator Function(BuildContext context) navigatorFinder;

  /// A callback that add a new [Location] to the provided navigator.
  ///
  /// This callback is invoked when [present] is called with the `arguments`
  /// Object that was passed to that method and the [KNavigator] obtained
  /// from [navigatorFinder].
  final (int, Future<T?>) Function(KNavigator navigator, Object? arguments) onPresent;

  /// A callback that is invoked when the [Location] added via [onPresent]
  /// completes.
  ///
  /// The return value of that location is passed to this method.
  @protected
  // This member should not be accessed directly outside of defining class.
  // ignore: unsafe_variance
  final void Function(T? result)? onComplete;

  /// Shows the location created by [onPresent] and invoke [onComplete] when it
  /// completes.
  void present([ Object? arguments, ]) {
    assert(!isPresent, 'location is already present');
    assert(isRegistered, 'restorable property is not registered');
    _hookOntoLocationFuture(
      onPresent(_navigator, arguments).$1,
    );
    notifyListeners();
  }

  int? _currentId;

  /// Whether the [Location] created by [present] is currently shown.
  ///
  /// Returns true after [present] has been called until the [Location]
  /// completes.
  bool get isPresent => _currentId != null;

  @override
  bool get enabled => _currentId != null;

  @override
  int? createDefaultValue() => null;

  @override
  void initWithValue(int? value) {
    if (value != null) {
      _hookOntoLocationFuture(value);
    }
  }

  @override
  Object? toPrimitives() {
    assert(_currentId != null, 'saved empty location future');
    return _currentId;
  }

  @override
  int? fromPrimitives(Object? data) {
    assert(data != null, 'restored empty location future');
    return data as int?;
  }

  KNavigator get _navigator => navigatorFinder(state.context);
  
  void _hookOntoLocationFuture(int value) {
    _currentId = value;
    final result = _navigator.getLocationResult<T>(value);
    assert(result != null, 'missing result of restored location future');
    unawaited(result?.then((value) {
      if (_disposed) {
        return;
      }
      _currentId = null;
      notifyListeners();
      onComplete?.call(value);
    }));
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
