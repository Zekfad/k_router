@experimental
library;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';


const double _kMinFlingVelocity = 1.0; // Screen widths per second.
// The duration for a page to animate when the user releases it mid-swipe.
const Duration _kDroppedSwipePageAnimationDuration = .new(milliseconds: 350);

/// A [CupertinoPage] that uses sophisticated hit testing modification in its
/// back gesture recognizer, allowing it to be used from any part of the screen,
/// including scrollable surfaces.
@experimental
class KCupertinoPage<T> extends CupertinoPage<T> {
  /// Create new [KCupertinoPage].
  @experimental
  const KCupertinoPage({
    required super.child,
    super.maintainState,
    super.title,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.canPop,
    super.onPopInvoked,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) => _PageBasedKCupertinoPageRoute<T>(
    page: this,
    allowSnapshotting: allowSnapshotting,
  );
}

class _PageBasedKCupertinoPageRoute<T> extends PageRoute<T>
  with CupertinoRouteTransitionMixin<T> {
  _PageBasedKCupertinoPageRoute({
    required KCupertinoPage<T> page,
    super.allowSnapshotting = true,
  }) : super(settings: page) {
    assert(opaque, 'Page route must be opaque');
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
    fullscreenDialog ? null : CupertinoPageTransition.delegatedTransition;

  CupertinoPage<T> get _page => settings as CupertinoPage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  String? get title => _page.title;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Check if the route has an animation that's currently participating
    // in a back swipe gesture.
    //
    // During back gesture drag use linear transition to match finger motion.
    final linearTransition = popGestureInProgress;
    if (fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: child,
      );
    } else {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: _CupertinoBackGestureDetector<T>(
          getPopGestureEnabled: () => popGestureEnabled,
          onStartPopGesture: () => .new(
            navigator: navigator!,
            getIsCurrent: () => isCurrent,
            getIsActive: () => isActive,
            controller: controller!,
          ),
          child: child,
        ),
      );
    }
  }
}

/// Special type of [HorizontalDragGestureRecognizer] that wins gesture arena
/// only when swiping to the same direction as current text direction.
class _BackDragGestureRecognizer extends HorizontalDragGestureRecognizer {
  _BackDragGestureRecognizer({
    required this.getTextDirection,
    super.debugOwner,
  });

  final ValueGetter<TextDirection> getTextDirection;
  OffsetPair? _initialPosition;

  @override
  void addPointer(PointerDownEvent event) {
    super.addPointer(event);
    _initialPosition = lastPosition;
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    final accept = super.hasSufficientGlobalDistanceToAccept(pointerDeviceKind, deviceTouchSlop);
    if (!accept) {
      return false;
    }
    final sign = (lastPosition.local.dx - _initialPosition!.local.dx).sign;
    return switch (getTextDirection()) {
      .ltr => sign > 0,
      .rtl => sign < 0,
    };
  }

  @override
  String get debugDescription => 'scroll aware horizontal drag';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty.has('getTextDirection', getTextDirection))
      ..add(DiagnosticsProperty('_initialPosition', _initialPosition, ifNull: '<uninitialized>'));
  }
}

/// Modified private class from SDK: _CupertinoBackGestureDetector
/// Replaced gesture detector with a custom one.
/// Replaced listener with a custom one.
class _CupertinoBackGestureDetector<T> extends StatefulWidget {
  const _CupertinoBackGestureDetector({
    required this.getPopGestureEnabled,
    required this.onStartPopGesture,
    required this.child,
    super.key,
  });

  final Widget child;

  final ValueGetter<bool> getPopGestureEnabled;

  final ValueGetter<_CupertinoBackGestureController<T>> onStartPopGesture;

  @override
  _CupertinoBackGestureDetectorState<T> createState() => _CupertinoBackGestureDetectorState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty.has('getPopGestureEnabled', getPopGestureEnabled))
      ..add(ObjectFlagProperty.has('onStartPopGesture', onStartPopGesture));
  }
}

class _CupertinoBackGestureDetectorState<T> extends State<_CupertinoBackGestureDetector<T>> {
  _CupertinoBackGestureController<T>? _backGestureController;

  late TextDirection _textDirection;
  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = _BackDragGestureRecognizer(
      getTextDirection: () => _textDirection,
      debugOwner: this
    )
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(debugCheckHasDirectionality(context), 'context is missing text direction');
    _textDirection = Directionality.of(context);
  }

  @override
  void dispose() {
    _recognizer.dispose();

    // If disposed during a drag gesture, call navigator.didStopUserGesture.
    if (_backGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_backGestureController?.navigator case final navigator? when navigator.mounted) {
          navigator.didStopUserGesture();
        }
        _backGestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted, 'state must be mounted');
    assert(_backGestureController == null, 'controller reinitialization');
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted, 'state must be mounted');
    assert(_backGestureController != null, 'controller is uninitialized');
    _backGestureController!.dragUpdate(
      _convertToLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted, 'state must be mounted');
    assert(_backGestureController != null, 'controller is uninitialized');
    _backGestureController!.dragEnd(
      _convertToLogical(details.velocity.pixelsPerSecond.dx / context.size!.width),
    );
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted, 'state must be mounted');
    // This can be called even if start is not called, paired with the "down" event
    // that we don't consider here.
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.getPopGestureEnabled()) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) => switch (_textDirection) {
    .rtl => -value,
    .ltr => value,
  };

  @override
  Widget build(BuildContext context) => _ListenerWithHitTestUnderScrollView(
    onPointerDown: _handlePointerDown,
    behavior: .translucent,
    child: widget.child,
  );
}

/// Special type of [Listener] that modifies hit test path to inject itself
/// below horizontal viewport if there are any.
///
/// Hit test path is ordered to start from the deepest child.
///
/// Since events are dispatched in hit test order, injecting listener below
/// viewport allows it to compete with drag recognizer used for scroll.
class _ListenerWithHitTestUnderScrollView extends Listener {
  const _ListenerWithHitTestUnderScrollView({
    super.onPointerDown,
    super.behavior,
    super.child,
  });

  @override
  _RenderListenerWithHitTestUnderScrollView createRenderObject(BuildContext context) => .new(
    textDirection: Directionality.of(context),
    onPointerDown: onPointerDown,
    onPointerMove: onPointerMove,
    onPointerUp: onPointerUp,
    onPointerHover: onPointerHover,
    onPointerCancel: onPointerCancel,
    onPointerPanZoomStart: onPointerPanZoomStart,
    onPointerPanZoomUpdate: onPointerPanZoomUpdate,
    onPointerPanZoomEnd: onPointerPanZoomEnd,
    onPointerSignal: onPointerSignal,
    behavior: behavior,
  );

  @override
  void updateRenderObject(BuildContext context, covariant _RenderListenerWithHitTestUnderScrollView renderObject) => renderObject
    ..textDirection = Directionality.of(context)
    ..onPointerDown = onPointerDown
    ..onPointerMove = onPointerMove
    ..onPointerUp = onPointerUp
    ..onPointerHover = onPointerHover
    ..onPointerCancel = onPointerCancel
    ..onPointerPanZoomStart = onPointerPanZoomStart
    ..onPointerPanZoomUpdate = onPointerPanZoomUpdate
    ..onPointerPanZoomEnd = onPointerPanZoomEnd
    ..onPointerSignal = onPointerSignal
    ..behavior = behavior;
}

class _RenderListenerWithHitTestUnderScrollView extends RenderPointerListener {
  _RenderListenerWithHitTestUnderScrollView({
    required this.textDirection,
    super.onPointerDown,
    super.onPointerMove,
    super.onPointerUp,
    super.onPointerHover,
    super.onPointerCancel,
    super.onPointerPanZoomStart,
    super.onPointerPanZoomUpdate,
    super.onPointerPanZoomEnd,
    super.onPointerSignal,
    super.behavior,
    super.child,
  });

  TextDirection textDirection;

  @override
  bool hitTest(BoxHitTestResult result, { required Offset position, }) {
    var hitTarget = false;
    if (size.contains(position)) {
      // collect true hit test path
      // we cannot just override BoxHitTestResult#add because other subclasses
      // use HitTestResult.wrap constructor which modifies private list directly.
      final container = BoxHitTestResult();
      final thisTarget = BoxHitTestEntry(this, position);
      hitTarget = hitTestChildren(container, position: position) || hitTestSelf(position);
      final includeSelf = hitTarget || behavior == .translucent;
      // special subclass that directly copies to private list bypassing any
      // safety checks
      final resultProxy = _CopyingBoxHitTestResult.wrap(result);
      // when copying path before which entry to insert this recognizer
      // this means that recognizer will be treated as a child of this element
      // so it will receive events before this member
      var insertBefore = -1;
      if (includeSelf) {
        // begin with parent and descend
        for (final (i, entry) in container.path.indexed.toList().reversed) {
          final HitTestTarget target;
          // See Scrollable build method
          if (entry.target case RenderPointerListener(
            child: RenderSemanticsAnnotations(
              child: RenderIgnorePointer(
                child: final RenderViewport trueTarget,
              ),
            ),
          )) {
            target = trueTarget;
          } else {
            target = entry.target;
          }
          if (target case RenderViewport(
            axis: .horizontal,
            :final axisDirection,
            :final ScrollPosition offset,
          )) {
            final checkBeginning = switch (textDirection) {
              .ltr => axisDirection == .right,
              .rtl => axisDirection == .left,
            };
            final inject = checkBeginning
              ? offset.pixels <= 0
              : offset.pixels >= offset.maxScrollExtent;
            if (inject) {
              insertBefore = i;
            } else {
              // viewport is scrolled, we dont want to interfere with it
              //
              // if parent viewport is not suitable for injection
              // do not consider going deeper, since it will win arena regardless
              break;
            }
          }
        }
      }
      for (final (i, entry) in container.path.indexed) {
        if (insertBefore == i) {
          resultProxy.add(thisTarget);
        }
        resultProxy.add(entry);
      }
      if (insertBefore == -1 && includeSelf) {
        result.add(thisTarget);
      }
    }
    return hitTarget;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('textDirection', textDirection));
  }
}

/// Special type of [BoxHitTestResult] that bypasses any assertions and unsafely
/// modifies path.
///
/// Used to copy already resolved hit test entries to target `result`.
class _CopyingBoxHitTestResult extends BoxHitTestResult {
  _CopyingBoxHitTestResult.wrap(super.result) : super.wrap();

  @override
  void add(HitTestEntry<HitTestTarget> entry) {
    (path as List<HitTestEntry>).add(entry);
  }
}

/// Private class from SDK:
/// _CupertinoBackGestureController
class _CupertinoBackGestureController<T> {
  /// Creates a controller for an iOS-style back gesture.
  _CupertinoBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;

  /// The drag gesture has changed by [delta]. The total range of the drag
  /// should be 0.0 to 1.0.
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  /// The drag gesture has ended with a horizontal motion of [velocity] as a
  /// fraction of screen width per second.
  void dragEnd(double velocity) {
    // Fling in the appropriate direction.
    //
    // This curve has been determined through rigorously eyeballing native iOS
    // animations.
    const Curve animationCurve = Curves.fastEaseInToSlowEaseOut;
    final isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      // If the page has already been navigated away from, then the animation
      // direction depends on whether or not it's still in the navigation stack,
      // regardless of velocity or drag position. For example, if a route is
      // being slowly dragged back by just a few pixels, but then a programmatic
      // pop occurs, the route should still be animated off the screen.
      // See https://github.com/flutter/flutter/issues/141268.
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      // If the user releases the page before mid screen with sufficient velocity,
      // or after mid screen, we should animate the page out. Otherwise, the page
      // should be animated back in.
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: _kDroppedSwipePageAnimationDuration,
        curve: animationCurve,
      );
    } else {
      if (isCurrent) {
        // This route is destined to pop at this point. Reuse navigator's pop.
        navigator.pop();
      }

      // The popping may have finished inline if already at the target destination.
      if (controller.isAnimating) {
        controller.animateBack(
          0.0,
          duration: _kDroppedSwipePageAnimationDuration,
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      // Keep the userGestureInProgress in true state so we don't change the
      // curve of the page transition mid-flight since CupertinoPageTransition
      // depends on userGestureInProgress.
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
