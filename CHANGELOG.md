## [0.0.6] - 10/5/2018.

* Added `useful_blocs.dart` to hold some built-in `Bloc`s that devs
  might want to use.
* Added `DebouncerBloc`, a Bloc capable of debouncing repeated actions.
  - Note that if an `Action` is cancelled by `DebouncerBloc`, any
    `Action` that has been given to its `afterward` method will also be
    cancelled.

## [0.0.5] - 9/11/2018.

* Added `afterward` method to the `Action` class.

## [0.0.4] - 8/27/2018.

* First release in which I remembered to update the change log.
* Two examples in place, plus the library itself.
* Seems relatively stable.
