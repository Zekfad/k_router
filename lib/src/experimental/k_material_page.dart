/// @docImport '../current_location.dart';
@experimental
library;

import 'package:material_ui/material_ui.dart';
import 'package:meta/meta.dart';

import '../k_navigator.dart';
import '../location.dart';


/// A [MaterialPage] that allows to correctly apply predictive back animation
/// to only active page depending on router state.
@experimental
class KMaterialPage<T> extends MaterialPage<T> {
  /// Create new [KMaterialPage].
  @experimental
  const KMaterialPage({
    required this.location,
    required super.child,
    super.maintainState = true,
    super.fullscreenDialog = false,
    super.allowSnapshotting = true,
    super.includeRouteSemantics = true,
    super.key,
    super.canPop,
    super.onPopInvoked,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// [Location] this page was created for, used to correctly configure
  /// [PredictiveBackRoute.popGestureEnabled] and prevent popping locations that
  /// are not indented to be popped by global back gesture.
  /// 
  /// Use [CurrentLocation.of] instead.
  final Location<T> location;

  @override
  Route<T> createRoute(BuildContext context) => _PageBasedKMaterialPageRoute<T>(
    page: this,
    allowSnapshotting: allowSnapshotting,
  );
}


/// A page-based version of [MaterialPageRoute].
///
/// This route uses the builder from the page to build its content. This ensures
/// the content is up to date after page updates.
class _PageBasedKMaterialPageRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  _PageBasedKMaterialPageRoute({
    required KMaterialPage<T> page,
    super.allowSnapshotting,
  }) : super(settings: page) {
    assert(opaque, 'material page must be opaque');
  }

  KMaterialPage<T> get _page => settings as KMaterialPage<T>;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  bool get includeRouteSemantics => _page.includeRouteSemantics;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  bool get popGestureEnabled => super.popGestureEnabled
    && KNavigator.getPopTargetLocation(navigator!.context) == _page.location;

  @override
  Widget buildContent(BuildContext context) => _page.child;
}
