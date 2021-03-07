// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart' hide Action;
import 'package:rxdart/subjects.dart';
import 'package:rxdart/streams.dart';

import 'engine.dart';

/// A [StatelessWidget] that provides [Store] access to its descendants via a
/// static [of] method.
class StoreProvider<S> extends StatefulWidget {
  final Store<S> store;
  final Widget child;
  final bool disposeStore;

  StoreProvider({
    required this.store,
    required this.child,
    this.disposeStore = false,
    Key? key,
  }) : super(key: key);

  static Store<S> of<S>(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_InheritedStoreProvider<S>>();

    if (widget == null) {
      throw Exception(
          'Couldn\'t find a StoreProvider of the correct type ($S).');
    } else {
      return (widget).store;
    }
  }

  @override
  _StoreProviderState<S> createState() => _StoreProviderState<S>();
}

class _StoreProviderState<S> extends State<StoreProvider<S>> {
  @override
  Widget build(BuildContext context) {
    return _InheritedStoreProvider<S>(store: widget.store, child: widget.child);
  }

  @override
  void dispose() {
    if (widget.disposeStore) {
      widget.store.dispose();
    }

    super.dispose();
  }
}

/// The [InheritedWidget] used by [StoreProvider].
class _InheritedStoreProvider<S> extends InheritedWidget {
  final Store<S> store;

  _InheritedStoreProvider({
    Key? key,
    required Widget child,
    required this.store,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedStoreProvider<S> oldWidget) =>
      (oldWidget.store != store);
}

/// Accepts a [BuildContext] and [ViewModel] and builds a Widget in response. A
/// [DispatchFunction] is provided so widgets in the returned subtree can
/// dispatch new actions to the [Store] in response to UI events.
typedef Widget ViewModelWidgetBuilder<S, V>(
    BuildContext context, DispatchFunction dispatcher, V viewModel);

/// Creates a new view model instance from the given state object. This method
/// should be used to narrow or filter the data present in [state] to the
/// minimum required by the [ViewModelWidgetBuilder] the converter will be used
/// with.
typedef V ViewModelConverter<S, V>(S state);

/// Transforms a stream of state objects found via [StoreProvider] into a stream
/// of view models, and builds a [Widget] each time a distinctly new view model
/// is emitted by that stream.
///
/// This class is designed to minimize the number of times its subtree is built.
/// When a new state is emitted by [Store.states], it's converted into a
/// view model using the provided [converter]. If (And only if) that new
/// instance is unequal to the previous one, the widget subtree is rebuilt using
/// [builder]. Any state changes emitted by the [Store] that don't impact the
/// view model used by a particular [ViewModelSubscriber] are ignored by it.
class ViewModelSubscriber<S, V> extends StatelessWidget {
  final ViewModelConverter<S, V> converter;
  final ViewModelWidgetBuilder<S, V> builder;

  ViewModelSubscriber({
    required this.converter,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Store<S> store = StoreProvider.of<S>(context);
    return _ViewModelStreamBuilder<S, V>(
        dispatcher: store.dispatch,
        stream: store.states,
        converter: converter,
        builder: builder);
  }
}

/// Does the actual work for [ViewModelSubscriber].
class _ViewModelStreamBuilder<S, V> extends StatefulWidget {
  final DispatchFunction dispatcher;
  final BehaviorSubject<S> stream;
  final ViewModelConverter<S, V> converter;
  final ViewModelWidgetBuilder<S, V> builder;

  _ViewModelStreamBuilder({
    required this.dispatcher,
    required this.stream,
    required this.converter,
    required this.builder,
  });

  @override
  _ViewModelStreamBuilderState createState() =>
      _ViewModelStreamBuilderState<S, V>();
}

/// Subscribes to a stream of app state objects, converts each one into a view
/// model, and then uses it to rebuild its children.
class _ViewModelStreamBuilderState<S, V>
    extends State<_ViewModelStreamBuilder<S, V>> {
  late V _latestViewModel;
  late StreamSubscription<V> _subscription;

  void _subscribe() {
    _latestViewModel = widget.converter(widget.stream.requireValue);
    _subscription = widget.stream
        .map<V>((s) => widget.converter(s))
        .distinct()
        .listen((viewModel) {
      setState(() => _latestViewModel = viewModel);
    });
  }

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  /// During stateful hot reload, the [_ViewModelStreamBuilder] widget is
  /// replaced, but this [State] object is not. It's important, therefore, to
  /// unsubscribe from the previous widget's stream and subscribe to the new
  /// one.
  @override
  void didUpdateWidget(_ViewModelStreamBuilder<S, V> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscription.cancel();
    _subscribe();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.dispatcher, _latestViewModel);
  }
}

/// Widget builder function that includes a [dispatcher] capable of dispatching
/// an [Action] to an inherited [Store].
typedef Widget DispatchWidgetBuilder(
    BuildContext context, DispatchFunction dispatcher);

/// Retrieves a [DispatcherFunction] from an ancestor [StoreProvider], and
/// builds builds widgets that can use it.
///
/// [DispatchSubscriber] is essentially a [ViewModelSubscriber] without the view
/// model part. It looks among its ancestors for a [Store] of the correct type,
/// and then builds widgets via a builder function that accepts the [Store]'s
/// dispatcher property as one of its parameters.
class DispatchSubscriber<S> extends StatelessWidget {
  DispatchSubscriber({
    required this.builder,
    Key? key,
  }) : super(key: key);

  final DispatchWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<S>(context);
    return builder(context, store.dispatch);
  }
}

/// Dispatches [action] to an inherited [Store] the first time it builds.
///
/// This widget is intended to help with actions that should be dispatched
/// automatically the first time a particular widget comes onscreen. For
/// example, an app may want to refresh certain data from a network when a
/// widget displaying a cached copy of that data is first displayed.
class FirstBuildDispatcher<S> extends StatefulWidget {
  const FirstBuildDispatcher({
    required this.action,
    required this.child,
    Key? key,
  }) : super(key: key);

  final Action action;
  final Widget child;

  @override
  _FirstBuildDispatcherState<S> createState() =>
      _FirstBuildDispatcherState<S>();
}

class _FirstBuildDispatcherState<S> extends State<FirstBuildDispatcher<S>> {
  bool hasDispatched = false;

  @override
  Widget build(BuildContext context) {
    if (!hasDispatched) {
      hasDispatched = true;
      final store = StoreProvider.of<S>(context);
      store.dispatch(widget.action);
    }

    return widget.child;
  }
}
