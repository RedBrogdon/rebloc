// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/subjects.dart' show BehaviorSubject;

/// A Redux-style action. Apps change their overall state by dispatching actions
/// to the [Store], where they are acted on by middleware and reducers. Apps can
/// use [afterward] to specify an [Action] that should be dispatched after the
/// current one is reduced.
abstract class Action {
  Action _next;

  Action();

  void afterward(Action a) {
    if (_next == null) {
      _next = a;
    } else {
      _next.afterward(a);
    }
  }

  factory Action.cancelled() => _CancelledAction();
}

/// An action that middleware methods can return in order to cancel (or
/// "swallow") an action already dispatched to their [Store]. Because rebloc
/// uses a stream to track [Actions] through the dispatch->middleware->reducer
/// pipeline, a middleware method should return something. By returning an
/// instance of this class (and making sure that none of their middleware or
/// reducer methods attempt to catch and act on it), a developer can in effect
/// cancel actions via middleware.
class _CancelledAction extends Action {
  @override
  void afterward(Action a) {}
}

/// A function that can dispatch an [Action] to a [Store].
typedef void DispatchFunction(Action action);

/// An accumulator for reducer functions.
///
/// [Store] offers each [Bloc] the opportunity to apply its own reducer
/// functionality in response to incoming [Action]s by subscribing to the
/// "reducer" stream, which is of type `<Stream<Accumulator<S>>`.
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

/// The context in which a middleware function executes.
///
/// In a manner similar to the streaming architecture used for reducers, [Store]
/// offers each [Bloc] the chance to apply middleware functionality to incoming
/// [Actions] by listening to the "dispatch" stream, which is of type
/// `Stream<MiddlewareContext<S>>`.
///
/// Middleware functions can examine the incoming [action] and current [state]
/// of the app, and dispatch new [Action]s using [dispatcher]. Afterward, they
/// should emit a new [MiddlewareContext] for the next [Bloc].
class MiddlewareContext<S> {
  final DispatchFunction dispatcher;
  final S state;
  final Action action;

  const MiddlewareContext(this.dispatcher, this.state, this.action);

  MiddlewareContext<S> copyWith(Action newAction) =>
      MiddlewareContext<S>(this.dispatcher, this.state, newAction);
}

/// A store for app state that manages the dispatch of incoming actions and
/// controls the stream of state objects emitted in response.
///
/// [Store] performs these tasks:
///
/// - Create a controller for the dispatch/reduce stream using an [initialState]
///   value.
/// - Wire each [Bloc] into the dispatch/reduce stream by calling its
///   [applyMiddleware] and [applyReducers] methods.
/// - Expose the [dispatcher] by which a new [Action] can be dispatched.
class Store<S> {
  final _dispatchController = StreamController<MiddlewareContext<S>>();
  final BehaviorSubject<S> states;

  Store({
    @required S initialState,
    List<Bloc<S>> blocs = const [],
  }) : states = BehaviorSubject<S>(seedValue: initialState) {
    var dispatchStream = _dispatchController.stream.asBroadcastStream();

    for (Bloc<S> bloc in blocs) {
      dispatchStream = bloc.applyMiddleware(dispatchStream);
    }

    var reducerStream = dispatchStream.map<Accumulator<S>>(
        (context) => Accumulator(context.action, states.value));

    for (Bloc<S> bloc in blocs) {
      reducerStream = bloc.applyReducer(reducerStream);
    }

    reducerStream.listen((a) {
      assert(a.state != null);
      states.add(a.state);
      if (a.action._next != null) {
        dispatcher(a.action._next);
      }
    });
  }

  // TODO(redbrogdon): Figure out how to guarantee that only one action is in
  // the stream at a time. Also figure out if that's really necessary.
  get dispatcher => (Action action) => _dispatchController
      .add(MiddlewareContext(dispatcher, states.value, action));
}

/// A Business logic component that can apply middleware and reducer
/// functionality to a [Store] by transforming the streams passed into its
/// [applyMiddleware] and [applyReducer] methods.
abstract class Bloc<S> {
  Stream<MiddlewareContext<S>> applyMiddleware(
      Stream<MiddlewareContext<S>> input);

  Stream<Accumulator<S>> applyReducer(Stream<Accumulator<S>> input);
}

typedef Action MiddlewareFunction<S>(
    DispatchFunction dispatcher, S state, Action action);
typedef S ReducerFunction<S>(S state, Action action);

/// A convenience [Bloc] class that handles the stream mapping bits for you.
/// Subclasses can simply override the [middleware] and [reducer] getters to
/// return their implementations.
abstract class SimpleBloc<S> implements Bloc<S> {
  @override
  Stream<MiddlewareContext<S>> applyMiddleware(
      Stream<MiddlewareContext<S>> input) {
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

  FutureOr<Action> middleware(
          DispatchFunction dispatcher, S state, Action action) =>
      action;

  S reducer(S state, Action action) => state;
}
