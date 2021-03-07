# rebloc

[![Build Status](https://travis-ci.org/RedBrogdon/rebloc.svg?branch=master)](https://travis-ci.org/RedBrogdon/rebloc)

A state management library for Flutter that combines aspects of Redux
and BLoC (this readme assumes some familiarity with both). It's a
personal project by [redbrogdon](https://github.com/redbrogdon),
rather than an official library from the Flutter team. You can
[find it on pub](https://pub.dartlang.org/packages/rebloc), Dart's
package manager.

## Adding rebloc to your project

Add this line to the project dependencies in your `pubspec.yaml`:

```yaml
rebloc: ^0.4.0
```

And use this import:

```dart
import 'package:rebloc/rebloc.dart';
```

## What's going on here

Rebloc is an attempt to smoosh together two popular Flutter state
management approaches: Redux and BLoC. It defines a Redux-y single
direction data flow that involves actions, middleware, reducers, and a
store. Rather than using functional programming techniques to compose
reducers and middleware from parts and wire everything up, however, it
uses BLoCs.

The store defines a dispatch stream that accepts new actions and
produces state objects in response. In between, BLoCs are wired into
the stream to function as middleware, reducers, and afterware. Afterware
is essentially a second chance for Blocs to perform middleware-like
tasks *after* the reducers have had their chance to update the app
state. The stream for a simple, two-BLoC store might look like this, for
example:

```
Dispatch ->
  BloC #1 middleware ->
  BLoC #2 middleware ->
  BLoC #1 reducer ->
  BLoC #2 reducer ->
  resulting state object is emitted by store ->
  BLoC #1 afterware ->
  BLoC #2 afterware ->
  Done
```

There are two ways to implement BLoCs. The first is a basic
`Bloc<StateType>` interface that allows direct access to the dispatch
stream (meaning you can transform it, expand it, and do all sorts of
other streamy goodness). The other is an abstract class,
`SimpleBloc<StateType>`, that hides away interaction with the stream and
provides a simple, functional interface.

Middleware and afterware methods can perform side effects like calling
out to REST endpoints and dispatching new actions, but reducers should
work as pure functions in keeping with Redux core principles. Middleware
and afterware are also allowed to cancel (or "swallow") actions.

## Why does this exist?

State management is an open question for Flutter developers. I like
the freedom of BLoCs, because a streaming interface can often turn what
would be weird async patterns into easily understood transforms, maps,
expands, and so on. On the other hand, I also like that the Redux
pattern can offer things like easily composed reducers and middleware,
great support for cross-cutting concerns like logging, and the potential
for time-travel debugging if interest merits building those sorts of
tools.

Thus I'd like to see if I can combine the two and get the parts I like
from both. Also, it's a chance to test out some widgets...

## ViewModelSubscriber

Included in this library is a widget called `ViewModelSubscriber`.
It looks for an InheritedWidget called `StoreProvider` above it to
find a stream of app state objects to subscribe to. Then it converts
each object that comes through the stream into a view model object and
builds widgets with it. This is similar to a `StreamBuilder`, but with
the benefit that a `ViewModelSubscriber` will ignore any state objects
that don't cause a change to its view model.

What this means in practice is that if you're building a piece of UI
that depends on one part of your overall app state, it will only be
rebuilt and redrawn if that one particular bit of data changes. If
you've got a list of complicated records, for example, you can use
`ViewModelSubscriber` widgets to avoid rebuilding the entire list just
because one field in one record changed.

## DispatchSubscriber

`DispatchSubscriber` is a `ViewModelSubscriber` without the view model.
If you have a piece of UI that just needs to dispatch an `Action` and
doesn't need any actual data from the `Store`, `DispatchSubscriber` is
your huckleberry.

## FirstBuildDispatcher

`FirstBuildDispatcher` automatically dispatches an `Action` to an
ancestor `Store` the first time it's built. If you'd like to refresh
some data from the network any time a particular widget is displayed,
for example, `FirstDispatchBuilder` can help.

## Basic example

Imagine an app that just needs to track a list of `int` as its only
state. You might have a class to represent the state of the app that
looks like this:

```dart
class AppState {
  List<int> numbers;

  AppState(this.numbers);
}
```

You might want to add a new number to the list, so you create an Action
class to trigger such a state change:

```dart
class AddNumberAction extends Action {
  final int newNumber;

  const AddNumberAction(this.newNumber);
}
```

To process that action, you'll need a BLoC, so you create one:

```dart
class NumbersBloc extends SimpleBloc<AppState> {
  @override
  AppState reducer(AppState state, Action action) {
    if (action is AddNumberAction) {
      final newList = List<int>.from(state.numbers)..add(action.newNumber);
      return AppState(newList);
    }

    return state;
  }
}
```

And you'll need a store to wire all this up for you, so you create one
in `main` and use a StoreProvider to propagate it down the tree:

```dart
void main() {
  final store = Store<AppState>(
    initialState: AppState([1, 2, 3]),
    blocs: [
      NumbersBloc(),
    ],
  );

  runApp(
    StoreProvider<AppState>(
      store: store,
      child: HomeScreen(),
    ),
  );
}
```

To build widgets with the data and dispatch new actions, you add a
`ViewModelSubscriber` to `HomeScreen` that looks like this:

```dart
ViewModelSubscriber<AppState, int>(
  converter: (state) => state.numbers.reduce((sum, val) => sum + val),
  builder: (context, dispatcher, model) => Center(
    child: Column(
      children: [
        Text('Sum of all the numbers: $model'),
        RaisedButton(
          child: Text('Add 3'),
          onPressed: () => dispatcher(AddNumberAction(3)),
        ),
        RaisedButton(
          child: Text('Add 0'),
          onPressed: () => dispatcher(AddNumberAction(0)),
        ),
      ],
    ),
  ),
)
```

Now when your user taps on one of the buttons, an action is dispatched
to the store. It's processed by the reducer and a new AppState
object is created. If the user hit the 'Add 3' button, the
`ViewModelSubscriber` will be rebuilt and show the new sum. If the user
hit the 'Add 0' button, the `ViewModelSubscriber` will not be rebuilt,
since the sum wasn't changed (even though there's a new number in the
list).

If you'd like to do something fancy like log every action to the
console, you can add a `middleware` function to the BLoC:

```dart
@override
FutureOr<Action> middleware(
    DispatchFunction dispatcher, AppState state, Action action) {
  if (action is AddNumberAction) {
    print('Adding a number: ${action.newNumber}.');
  }

  return action;
}
```

## Example app

An [example app](https://github.com/RedBrogdon/rebloc/tree/master/example)
is included in the repo to illustrate what real-world use of rebloc might
look like. It includes two demos: a simple, "hit a button to dispatch an 
action" screen and a list-based demo that shows a Bloc dispatching a
steady stream of actions on its own.

## Feedback

I'm interested in whatever feedback other devs in the Flutter community
may have, whether it's "This is awesome" or "This design is bad and you
should feel bad." Feel free to file issues and feature requests, tweet
at [@RedBrogdon](https://twitter.com/redbrogdon), and come join the
conversation at the
[Flutter Dev Google group](https://groups.google.com/forum/#!forum/flutter-dev).
