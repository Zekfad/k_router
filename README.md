# K Router

A general purpose Navigator 2.0 router for large scale applications with
intricate navigation scenarios and full state restoration.

## Features

* __Full restoration support__ - this router is designed for state restoration
  support from the ground up. Duplicate routes, nested shells, parallel
  histories are all preserved. Every page is provided with restoration ID
  allowing for a seamless restoration.
* __Imperative API__ - this router API provides imperative calls that mutate
  internal tree-like navigation stack.
* __Deep linking__ with __custom logic__ - you have full control on how to
  handle incoming deep-links be it push new location, replace navigation stack
  or completely ignore deep-link, trigger custom side effects. It's easy to
  prevent old or incompatible URIs from breaking your navigation.
* __Parallel navigation__ - this router represents navigation stack as tree-like
  structure, allowing for a common navigation patterns and a unique multi-shell
  pattern. You can easily host multiple navigators on a single page and have
  them keep theirs history. See `ShellLocation` and `MultiLocation` for more.
* __Easy `Page` modification__ - you can easily replace existing route's `Page`,
  allowing you to quickly update `CupertinoPage`'s name or page URI and it's
  parameters.
* __Browser history support__ - restoration data is in sync with browser's
  history, so you press back or forward as on any web-page and router will
  handle it.

## Limitations

* You have to bring your own URI-to-Location mapping mechanism (if you need it).

  I suggest using radix tree or prefix tree for this matter.

* This router __DOES NOT__ provide any location guards, because restoration can
  bypass them. But in exchange router internals can avoid asynchronous
  computations in restoration save/load.

  I advice you to create your own abstraction for checking location's required
  permissions before pushing it and implementing same check inside of location's
  UI.

* Because of [Flutter#152323](https://github.com/flutter/flutter/issues/152323)
  to properly support predictive back with shell or multi shell locations, use
  experimental `KMaterialPage` or hook `KNavigator.getPopTargetLocation` to
  your `Route.popGestureEnabled`.
