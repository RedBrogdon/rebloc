// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxdart/subjects.dart' show BehaviorSubject;

import 'engine.dart';

/// A [StatelessWidget] that provides [Store] access to its descendants via a
/// static [of] method.
class StoreProvider<S> extends StatelessWidget {
  final Store<S> store;
  final Widget child;

  StoreProvider({
    @required this.store,
    @required this.child,
    Key key,
  }) : super(key: key);

  static Store<S> of<S>(
    BuildContext context, {
    bool rebuildOnChange = false,
  }) {
    final Type type = _type<_InheritedStoreProvider<S>>();

    Widget widget = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(type)
        : context.ancestorWidgetOfExactType(type);

    if (widget == null) {
      throw Exception(
          'Couldn\'t find a StoreProvider of the correct type ($type).');
    } else {
      return (widget as _InheritedStoreProvider<S>).store;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedStoreProvider<S>(store: store, child: child);
  }

  static Type _type<T>() => T;
}

/// The [InheritedWidget] used by [StoreProvider].
class _InheritedStoreProvider<S> extends InheritedWidget {
  final Store<S> store;

  _InheritedStoreProvider({Key key, Widget child, this.store})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedStoreProvider<S> oldWidget) =>
      (oldWidget.store != store);
}

/// A subset (or "view") of the data contained in state object emitted by a
/// [Store], plus a dispatcher for dispatching new actions to that store.
class ViewModel<S> {
  final DispatchFunction dispatcher;

  const ViewModel(this.dispatcher);
}

/// Accepts a [BuildContext] and [ViewModel] and builds a Widget in response.
typedef Widget ViewModelWidgetBuilder<S, V extends ViewModel<S>>(
    BuildContext context, V viewModel);

/// Creates a new view model instance from a state object.
typedef V ViewModelConverter<S, V extends ViewModel<S>>(
    DispatchFunction dispatcher, S state);

/// Transforms a stream of state objects found via [StoreProvider] into a stream
/// of view models, and builds a [Widget] each time a new view model is emitted.
class ViewModelSubscriber<S, V extends ViewModel<S>> extends StatelessWidget {
  final ViewModelConverter<S, V> converter;
  final ViewModelWidgetBuilder<S, V> builder;

  ViewModelSubscriber(
      {@required this.converter, @required this.builder, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Store<S> store = StoreProvider.of<S>(context);
    return _ViewModelStreamBuilder<S, V>(
        dispatcher: store.dispatcher,
        stream: store.states,
        converter: converter,
        builder: builder);
  }
}

/// Does the actual work for [ViewModelSubscriber].
class _ViewModelStreamBuilder<S, V extends ViewModel<S>>
    extends StatefulWidget {
  final DispatchFunction dispatcher;
  final BehaviorSubject<S> stream;
  final ViewModelConverter<S, V> converter;
  final ViewModelWidgetBuilder<S, V> builder;

  _ViewModelStreamBuilder({
    @required this.dispatcher,
    @required this.stream,
    @required this.converter,
    @required this.builder,
  });

  @override
  _ViewModelStreamBuilderState createState() =>
      _ViewModelStreamBuilderState<S, V>();
}

/// Subscribes to a stream of app state objects, converts each one into a view
/// model, and then uses it to rebuild its children.
class _ViewModelStreamBuilderState<S, V extends ViewModel<S>>
    extends State<_ViewModelStreamBuilder<S, V>> {
  V _latestViewModel;
  StreamSubscription<V> _subscription;

  void _subscribe() {
    _latestViewModel = widget.converter(widget.dispatcher, widget.stream.value);
    _subscription = widget.stream
        .map<V>((s) => widget.converter(widget.dispatcher, s))
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

  @override
  void didUpdateWidget(_ViewModelStreamBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscription.cancel();
    _subscribe();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _subscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _latestViewModel);
  }
}
