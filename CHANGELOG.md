## [0.3.0] - 8/1/2019

* Breaking change: Added disposal of stores and blocs.
  - The `Bloc` interface now has a fourth method, `dispose`. Blocs
    should implement this method to close/dispose of any resources
    they use. A Bloc should not expect any of its other methods to be
    invoked after it's disposed.
  - The `Store` class now has a `dispose` method as well. This will
    clean up any resources used by the store and invoke `dispose` on
    any Blocs it was given in its constructor.
  - The `StoreProvider` widget gains an optional named parameter to
    its constructor, `disposeStore`. False by default, if this flag
    is set to true, the `StoreProvider` will call `dispose` on its
    store when its State object is disposed.
* Refactored examples from a pair of apps into a single one. Also
  consolidated tests.
  - The "simple" example uses a long-lived `Store`, and the list
    example uses the new `dispose` functionality to create a new
    Store whenever it's shown.

## [0.2.0] - 10/18/2018

* Breaking change: Added the concept of "afterware" to the library.
  - Afterware are middle-ware like functions that are invoked after an
    `Action` has passed the reducing stage. If you need to perform a
    side effect after the app state has been updated in response to a
    given `Action` (e.g. save state to disk, dispatch other actions),
    afterware is the place to do it.

## [0.1.0] - 10/17/2018

* Began using Dart versioning correctly.
* Added `FirstBuildDispatcher`, a new widget that will dispatch an
  `Action` to an ancestor `Store` the first time it's built.

## [0.0.7] - 10/7/2018

* Changed `StoreProvider` to always use `inheritFromWidgetOfExactType`.
* Added `DispatchSubscriber`, a widget that subscribes to an ancestor
  `StoreProvider`'s dispatch function and builds widgets that can call
  it.

## [0.0.6] - 10/5/2018

* Added `useful_blocs.dart` to hold some built-in `Bloc`s that devs
  might want to use.
* Added `DebouncerBloc`, a Bloc capable of debouncing repeated actions.
  - Note that if an `Action` is cancelled by `DebouncerBloc`, any
    `Action` that has been given to its `afterward` method will also be
    cancelled.

## [0.0.5] - 9/11/2018

* Added `afterward` method to the `Action` class.

## [0.0.4] - 8/27/2018

* First release in which I remembered to update the change log.
* Two examples in place, plus the library itself.
* Seems relatively stable.
