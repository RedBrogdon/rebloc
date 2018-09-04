# rebloc

A state management library for Flutter that combines aspects of Redux
and BLoC (this readme assumes some familiarity with both. It's a
personal experiment by [redbrogdon](https://github.com/redbrogdon),
rather than an official library from the Flutter team.

## What's going on here

Rebloc is an attempt to smoosh together two popular Flutter state
management approaches: Redux and BLoC. It defines a Redux-y single
direction data flow that involves actions, middleware, reducers, and a
store. Rather than using functional programming techniques to compose
reducers and middleware from parts and wire everything up, however, it
uses BLoCs.

![img](https://i.imgur.com/aMuwpWS.png)

The store defines a dispatch stream that accepts new actions and
produces state objects in response. In between, BLoCs are wired into
the stream to function as middleware and reducers. The stream for a
simple, two-BLoC store might look like this, for example:

```
Dispatch ->
  BloC #1 middleware ->
  BLoC #2 middleware ->
  the action becomes an accumulator (action and state together) ->
  BLoC #1 reducer ->
  BLoC #2 reducer ->
  resulting state object is emitted by store
```

There are two ways to implement BLoCs. The first is a basic
`Bloc<StateType>` interface that allows direct access to the dispatch
stream (meaning you can transform it, expand it, and do all sorts of
other streamy goodness). The other is an abstract class,
`SimpleBloc<StateType>`, that hides away interaction with the stream and
provides a simple, functional interface.

## Why does this exist?

State management is an open question for Flutter developers. I like
the freedom of BLoCs, but the Redux pattern can offer things like
easily composed reducers and middleware, great support for cross-cutting
concerns like logging, and the potential for time-travel debugging if
interest merits building those sorts of tools.

Thus I'd like to see if I can combine the two and get the parts I like
from both. Also, it's a chance to test out...

## ViewModelSubscriber

Also included in this library is a widget called `ViewModelSubscriber`.
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

## Examples

Two examples are included (a
[basic one](https://github.com/RedBrogdon/rebloc/tree/master/example),
and a [list-based one](https://github.com/RedBrogdon/rebloc/tree/master/listexample))
so you can see the library in action. It's also being used in the
[Voxxed Days conference app](https://github.com/redbrogdon/voxxedapp)
currently being built.

## Feedback

I'm interested in whatever feedback other devs in the Flutter community
may have, whether it's "This is awesome" or "This design is bad and you
should feel bad." Feel free to file issues and feature requests, tweet
at [@RedBrogdon](https://twitter.com/redbrogdon), and come join the
conversation at the
[Flutter Dev Google group](https://groups.google.com/forum/#!forum/flutter-dev).