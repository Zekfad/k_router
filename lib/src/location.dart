/// @docImport 'package:flutter/cupertino.dart';
/// @docImport 'package:flutter/material.dart';
/// @docImport 'package:k_router/k_router.dart';
library;

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'location_codec.dart';
import 'location_discriminator.dart';


/// Base interface for navigator location.
/// 
/// Locations are single-use objects, you MUST never reuse location object
/// because it's automatically disposed by navigator after it's served it's
/// purpose.
@optionalTypeArgs
abstract interface class Location<T> implements Listenable {
  /// Location discriminator.
  /// 
  /// __MUST__ be unique for each user location class.
  LocationDiscriminator get discriminator;
  /// Location URI, can be updated and update will be applied as soon as router
  /// picks up navigation stack update.
  Uri get uri;
  /// Location name for Cupertino style pages, can be updated and update will be
  /// visible as soon as router picks up navigation stack update.
  String? get title;

  /// Create page for insertion into [Navigator.pages].
  /// 
  /// You __MUST__ pass [key] to [Page.key]. Because this page will
  /// be recreated occasionally and moved around in [Navigator.pages] this is
  /// required to correctly preserve page state.
  /// 
  /// You __MUST__ pass [name] to [Page.name]. Flutter internally uses name in
  /// some cases and it must be a valid [Uri] (naming is a bit confusing).
  /// 
  /// You __MUST__ pass [restorationId] to [Page.restorationId]. This ensures
  /// correct state restoration for page and it's contents.
  /// 
  /// You __MUST__ pass [child] to [MaterialPage.child]/[CupertinoPage.child].
  /// 
  /// This method can be called multiple times (for example after location
  /// updates). You should not reference returned page object directly.
  /// 
  /// If you're converting [Route] to [Page] by overriding [Page.createRoute],
  /// you should reference page only though [Route.settings] getter which will
  /// always point to an actual page object.
  /// 
  /// {@template location_build_context}
  /// This method is executed in [context] of [AppNavigator], you may consider
  /// using [Builder] or [StatefulWidget] for acquiring new context.
  /// {@endtemplate}
  /// 
  @factory
  Page<T> buildPage(BuildContext context, {
    required LocalKey key,
    required String name,
    required String restorationId,
    required Widget child,
  });

  /// Build method for page content.
  /// 
  /// Result of this method will be passed to [buildPage] as `child` parameter.
  /// 
  /// {@macro location_build_context}
  Widget build(BuildContext context);

  /// Dispose this location and it's resources.
  @mustCallSuper
  void dispose();
}

@internal
sealed class LocationWithChildren<T> implements Location<T> {
  /// {@template location_children}
  /// This list is not reactive and checked only when you push location.
  /// 
  /// __MUST__ not be empty.
  /// {@endtemplate}
  List<Location<Object?>> get children;
}

/// Location that allows you to render nested navigator with a custom shell.
@optionalTypeArgs
abstract interface class ShellLocation<T> implements LocationWithChildren<T> {
  /// Initial children for this shell.
  /// 
  /// {@macro location_children}
  @override
  List<Location<Object?>> get children;

  @override
  Page<T> buildPage(BuildContext context, {
    required LocalKey key,
    required String name,
    required String restorationId,
    required Widget child,
  });

  /// Build method for page content.
  /// 
  /// Result of this method will be passed to [buildPage] as `child` parameter
  /// or it can be used inline as part of shell for multi location.
  /// 
  /// {@macro location_build_context}
  @override
  Widget build(BuildContext context, {
    Widget? navigator,
  });
}

/// Location that allows you to render multiple parallel navigators with shells.
/// 
/// __Note__: beware that [children] shells are rendered as part of this
/// location, which means that hero widgets that are part of shells can cause
/// duplication issue.
@optionalTypeArgs
abstract interface class MultiLocation<T> implements LocationWithChildren<T> {
  /// Initial child shells for this multi location.
  /// 
  /// {@macro location_children}
  @override
  List<ShellLocation<Object?>> get children;

  @override
  Page<T> buildPage(BuildContext context, {
    required LocalKey key,
    required String name,
    required String restorationId,
    required Widget child,
    int? activeIndex,
  });

  @override
  Widget build(BuildContext context, {
    int? activeIndex,
    List<Widget>? children,
  });
}

/// Mixin/interface that indicates location can encode it's state via
/// [encodeState] method.
@optionalTypeArgs
mixin LocationWithStateEncoder<T> on Location<T> {
  /// Convert this location state to serializable format.
  LocationEncoded encodeState();
}
