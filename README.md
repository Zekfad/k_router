# K Router <sup>experimental</sup>

A general Navigator 2.0 router created for production use.

Here's the list of features this implementation provides:

* __Imperative API__ - this router API consists of imperative calls that mutate
  tree-like navigation stack.
* Deep linking - supports __custom logic for deep-links__: you can push new
  location or ignore deep-link for example to trigger custom side effects. This
  is a useful feature to prevent errors with incompatible URIs, since users can
  have outdated version of your app.
* __Full restoration support__ - this router is designed for state restoration
  support from the start, even parallel navigation chains are preserved. Every
  location's page is provided with restoration ID removing clashes and allowing
  for a seamless restoration of duplicate routes.
* Tree navigation stack - this router supports not only normal routes, but also
  shell (__nested navigation__) and parallel multi shell pages (__multiple
  nested navigators on a single screen__). You can also nest them.
* `Page` modification - this router allows you to replace `Page` object and
  re-render route with new data, such as __updating URI__ or name for
  `CupertinoPage`.
* Browser history support - because this router requires restoration it allows
  for a better handling of __browser back and forward__ action.

Currently this router provides the bare minimum required for it's proper
operation. You have to bring your own Uri-to-Location mapping mechanism if you
need it.

Currently this router __does not__ support predictive back with shell or multi
locations because of
[Flutter#152323](https://github.com/flutter/flutter/issues/152323).
