# K Router

A general purpose Navigator 2.0 router created for production use. Created to
allow more intricate navigation scenarios often found in large application.

Here's the list of features this implementation provides:

* __Full restoration support__ - this router is designed for state restoration
  support from the start, even parallel navigation chains are preserved. Every
  location's page is provided with restoration ID removing clashes and allowing
  for a seamless restoration of duplicate routes.
* __Imperative API__ - this router API consists of imperative calls that mutate
  tree-like navigation stack.
* Deep linking - supports __custom logic for deep-links__: you can push new
  location or ignore deep-link and trigger custom side effects. This feature is
  crucial to prevent errors with incompatible URIs.
* Tree navigation stack - this router supports not only normal routes, but also
  shell (__nested navigation__) and parallel multi shell pages (__multiple
  nested navigators on a single screen__). You can also nest them in any way.
  A clean way to implement bottom navigation with parallel navigation in tabs.
* `Page` modification - this router allows you to replace `Page` object and
  re-render route with new data, such as __updating URI__, name for
  `CupertinoPage` or any custom state.
* Browser history support - because this router requires restoration it allows
  for a better handling of __browser back and forward__ action.

Currently this router provides the necessary minimum for it's proper operation.
Which creates following limitations:

* You have to bring your own Uri-to-Location mapping mechanism (if you need it).

  I suggest using radix tree or prefix tree for this matter.

* This router __DOES NOT__ provide any location guards, because restoration can
  bypass them. But in exchange it's internals can avoid asynchronous
  computations in restoration save/load.

  I advice you to create your own abstraction for checking location's required
  permissions AND implementing same check inside of location's UI.

* Because of [Flutter#152323](https://github.com/flutter/flutter/issues/152323)
  to properly support predictive back with shell or multi shell locations, use
  experimental `KMaterialPage` or hook `KNavigator.getPopTargetLocation` to
  your `Route.popGestureEnabled`.
