// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/subjects.dart' show BehaviorSubject;

/// A Redux-style action. Apps change their overall state by dispatching actions
/// to the [Store], where they are acted on by middleware, reducers, and
/// afterware in that order.
abstract class Action {
  const Action();
  factory Action.cancelled() => _CancelledAction();
}

/// An action that middleware and afterware methods can return in order to
/// cancel (or "swallow") an action already dispatched to their [Store]. Because
/// rebloc uses a stream to track [Actions] through the
/// dispatch->middleware->reducer pipeline, a middleware/afterware method should
/// return something. By returning an instance of this class (which is private
/// to this library), a developer can in effect cancel actions via middleware.
class _CancelledAction extends Action {
  const _CancelledAction();
}

/// A function that can dispatch an [Action] to a [Store].
typedef void DispatchFunction(Action action);

/// An accumulator for reducer functions.
///
/// [Store] offers each [Bloc] the opportunity to apply its own reducer
/// functionality in response to incoming [Action]s by subscribing to the
/// "reducer" stream, which is of type `Stream<Accumulator<S>>`.
///
/// A [Bloc] that does so is expected use the [Action] and [state] provided in
/// any [Accumulator] it receives to calculate a new [state], then emit it in a
/// new Accumulator with the original action and new [state].
class Accumulator<S> {
  final Action action;
  final S state;

  const Accumulator(this.action, this.state);

  Accumulator<S> copyWith(S newState) => Accumulator<S>(this.action, newState);
}

/// The context in which a middleware or afterware function executes.
///
/// In a manner similar to the streaming architecture used for reducers, [Store]
/// offers each [Bloc] the chance to apply middleware and afterware
/// functionality to incoming [Actions] by listening to the "dispatch" stream,
/// which is of type `Stream<WareContext<S>>`.
///
/// Middleware and afterware functions can examine the incoming [action] and
/// current [state] of the app and perform side effects (including dispatching
/// new [Action]s using [dispatcher]. Afterward, they should emit a new
/// [WareContext] for the next [Bloc].
class WareContext<S> {
  final DispatchFunction dispatcher;
  final S state;
  final Action action;

  const WareContext(this.dispatcher, this.state, this.action);

  WareContext<S> copyWith(Action newAction) =>
      WareContext<S>(this.dispatcher, this.state, newAction);
}

/// A store for app state that manages the dispatch of incoming actions and
/// controls the stream of state objects emitted in response.
///
/// [Store] performs these tasks:
///
/// - Create a controller for the dispatch/reduce stream using an [initialState]
///   value.
/// - Wire each [Bloc] into the dispatch/reduce stream by calling its
///   [applyMiddleware], [applyReducers], and [applyAfterware] methods.
/// - Expose the [dispatcher] with which a new [Action] can be dispatched.
class Store<S> {
  final _dispatchController = StreamController<WareContext<S>>();
  final _afterwareController = StreamController<WareContext<S>>();
  final BehaviorSubject<S> states;

  Store({
    @required S initialState,
    List<Bloc<S>> blocs = const [],
  }) : states = BehaviorSubject<S>(seedValue: initialState) {
    var dispatchStream = _dispatchController.stream.asBroadcastStream();
    var afterwareStream = _afterwareController.stream.asBroadcastStream();

    for (Bloc<S> bloc in blocs) {
      dispatchStream = bloc.applyMiddleware(dispatchStream);
      afterwareStream = bloc.applyAfterware(afterwareStream);
    }

    var reducerStream = dispatchStream.map<Accumulator<S>>(
        (context) => Accumulator(context.action, states.value));

    for (Bloc<S> bloc in blocs) {
      reducerStream = bloc.applyReducer(reducerStream);
    }

    reducerStream.listen((a) {
      assert(a.state != null);
      states.add(a.state);
      _afterwareController.add(WareContext<S>(dispatcher, a.state, a.action));
    });

    // Without something listening, the afterware won't be executed.
    afterwareStream.listen((_) {});
  }

  get dispatcher => (Action action) =>
      _dispatchController.add(WareContext(dispatcher, states.value, action));
}

/// A Business logic component that can apply middleware, reducer, and
/// afterware functionality to a [Store] by transforming the streams passed into
/// its [applyMiddleware], [applyReducer], and [applyAfterware] methods.
abstract class Bloc<S> {
  Stream<WareContext<S>> applyMiddleware(Stream<WareContext<S>> input);

  Stream<Accumulator<S>> applyReducer(Stream<Accumulator<S>> input);

  Stream<WareContext<S>> applyAfterware(Stream<WareContext<S>> input);
}

/// A convenience [Bloc] class that handles the stream mapping bits for you.
/// Subclasses can simply override [middleware], [reducer], and [afterware] to
/// add their implementations.
abstract class SimpleBloc<S> implements Bloc<S> {
  @override
  Stream<WareContext<S>> applyMiddleware(Stream<WareContext<S>> input) {
    return input.asyncMap((context) async {
      return context.copyWith(
          await middleware(context.dispatcher, context.state, context.action));
    });
  }

  @override
  Stream<Accumulator<S>> applyReducer(Stream<Accumulator<S>> input) {
    return input.map<Accumulator<S>>((accumulator) {
      return accumulator
          .copyWith(reducer(accumulator.state, accumulator.action));
    });
  }

  @override
  Stream<WareContext<S>> applyAfterware(Stream<WareContext<S>> input) {
    return input.asyncMap((context) async {
      return context.copyWith(
          await afterware(context.dispatcher, context.state, context.action));
    });
  }

  FutureOr<Action> middleware(
          DispatchFunction dispatcher, S state, Action action) =>
      action;

  FutureOr<Action> afterware(
          DispatchFunction dispatcher, S state, Action action) =>
      action;

  S reducer(S state, Action action) => state;
}
