/// @docImport 'location_function_codec.dart';
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialPage;
import 'package:flutter/widgets.dart';

import 'location.dart';
import 'location_codec.dart';
import 'location_pop_type.dart';


/// {@template k_router_base_location_header}
/// Base implementation for a simple location based on [MaterialPage].
/// {@endtemplate}
/// 
/// {@template k_router_base_location_ctors}
/// You have 2 constructors:
/// * Unnamed constructor is used for creating location for pushing/replacing.
/// * `fromOptions` constructor is useful factory for using with [LocationFunctionCodec]
/// {@endtemplate}
@optionalTypeArgs
abstract base class BaseLocation<T> with ChangeNotifier, LocationPopType<T> implements Location<T>  {
  /// {@macro k_router_base_location_header}
  BaseLocation({
    required Uri uri,
    String? title,
  }) : _title = title, _uri = uri {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
      FlutterMemoryAllocations.instance.dispatchObjectCreated(
        library: 'package:k_router/k_router.dart',
        className: 'BaseLocation',
        object: this,
      );
    }
  }

  /// {@macro k_router_base_location_header}
  BaseLocation.fromOptions(LocationOptions options) : this(
    uri: options.uri,
    title: options.title,
  );

  Uri _uri;
  String? _title;

  @override
  Uri get uri => _uri;
  set uri(Uri value) {
    if (_uri == value) {
      return;
    }
    _uri = value;
    notifyListeners();
  }

  @override
  String? get title => _title;
  set title(String? value) {
    if (_title == value) {
      return;
    }
    _title = value;
    notifyListeners();
  }

  @override
  Page<T> buildPage(BuildContext context, {
    required String restorationId,
  }) => MaterialPage(
    key: ValueKey(this),
    restorationId: restorationId,
    name: uri.toString(),
    // title: title,
    child: build(context),
  );

  @override
  void dispose() {
    super.dispose();
    if (kFlutterMemoryAllocationsEnabled) {
      FlutterMemoryAllocations.instance.dispatchObjectDisposed(
        object: this,
      );
    }
  }
}

/// {@template k_router_base_multi_location_header}
/// Base implementation for a multi location based on [MaterialPage].
/// {@endtemplate}
/// 
/// {@macro k_router_base_location_ctors}
@optionalTypeArgs
abstract base class BaseMultiLocation<T> extends BaseLocation<T> implements MultiLocation<T> {
  /// {@macro k_router_base_multi_location_header}
  BaseMultiLocation({
    required super.uri,
    super.title,
  });

  /// {@macro k_router_base_multi_location_header}
  BaseMultiLocation.fromOptions(LocationOptions options) : this(
    uri: options.uri,
    title: options.title,
  );

  @override
  Page<T> buildPage(BuildContext context, {
    required String restorationId,
    List<Widget>? children,
    int? activeIndex,
  }) => MaterialPage(
    key: ValueKey(this),
    restorationId: restorationId,
    name: uri.toString(),
    // title: title,
    child: build(
      context,
      children: children,
      activeIndex: activeIndex,
    ),
  );
}

/// {@template k_router_base_shell_location_header}
/// Base implementation for a shell location based on [MaterialPage].
/// {@endtemplate}
/// 
/// {@macro k_router_base_location_ctors}
@optionalTypeArgs
abstract base class BaseShellLocation<T> extends BaseLocation<T> implements ShellLocation<T> {
  /// {@macro k_router_base_shell_location_header}
  BaseShellLocation({
    required super.uri,
    super.title,
  });

  /// {@macro k_router_base_shell_location_header}
  BaseShellLocation.fromOptions(LocationOptions options) : this(
    uri: options.uri,
    title: options.title,
  );

  @override
  Page<T> buildPage(BuildContext context, {
    required String restorationId,
    Widget? navigator,
  }) => MaterialPage(
    key: ValueKey(this),
    restorationId: restorationId,
    name: uri.toString(),
    // title: title,
    child: build(context, navigator: navigator),
  );
}
