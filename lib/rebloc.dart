// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Rebloc is a modified implementation of the [Redux](https://redux.js.org/)
/// pattern using techniques more idiomatic to Flutter and Dart. Plus there's
/// blocs.
///
/// Here, [Bloc] is used to mean a business logic class that accepts input and
/// creates output solely through streams. Each [Bloc] is given two chances to
/// act in response to incoming actions: first as middleware, and again as a
/// reducer.
///
/// Rather than using functional programming techniques to combine reducers and
/// middleware, Rebloc uses a stream-based approach. A Rebloc [Store] creates
/// a dispatch stream for receiving new [Action]s, and invites [Bloc]s to
/// subscribe and manipulate the stream to apply their middleware and reducer
/// functionality. Where in Redux, one middleware function is responsible for
/// calling the next, with Rebloc a middleware function receives an action from
/// its input stream and (after logging, kicking off async APIs, dispatching new
/// actions, etc.) is responsible for emitting it on its output stream so the
/// next [Bloc] will have a chance to act. If the middleware function needs to
/// cancel the action, of course, it can just emit nothing.
///
/// After middleware processing is complete, the Stream of [Action]s is mapped
/// to one of [Accumulator]s, and each [Bloc] is given a chance to apply reducer
/// functionality in a similar manner. When finished, the resulting app state is
/// added to the [Store]'s `states` stream, and changes can be picked up by
/// [ViewModelSubscriber] widgets.
///
/// [ViewModelSubscriber] is intended to be the sole mechanism by which widgets
/// are built from the data emitted by the [Store] and wired up to dispatch
/// [Action]s to it. [ViewModelSubscriber] is similar to [StreamBuilder] in that
/// it listens to a stream and builds widgets in response, but with a few key
/// differences:
///
/// - It looks for a [StoreProvider] ancestor in order to get a reference to a
///   [Store] of matching type.
/// - It assumes the stream will always have a value on subscription (an RxDart
///   BehaviorSubject is used by [Store] to ensure this). As a result, it has no
///   mechanism for connection states or snapshots that don't contain data.
/// - It converts the app state objects it receives into view models using a
///   required `converter` function, and ignores any changes to the app state
///   that don't cause a change in its view model, limiting rebuilds.
/// - It provides to its builder method not only the most recent view model, but
///   also a reference to the [Store]'s `dispatcher` method, so new [Action]s
///   can be dispatched in response to user events like button presses.

library rebloc;

export 'src/engine.dart';
export 'src/widgets.dart';
