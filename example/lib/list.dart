// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:example/utils.dart';
import 'package:flutter/material.dart' hide Action, Accumulator;
import 'package:rebloc/rebloc.dart';

class ListAppState {
  final Map<String, int> namesAndCounts;

  const ListAppState(this.namesAndCounts);

  const ListAppState.initialState()
      : namesAndCounts = const {
          'Steve': 1,
        };

  ListAppState copyWith(Map<String, int> newData) {
    return ListAppState(Map.from(this.namesAndCounts)..addAll(newData));
  }

  String toString() => namesAndCounts.toString();
}

class StartStreamOfIncrementsAction extends Action {}

class IncrementAction extends Action {
  final String name;

  IncrementAction(this.name);
}

class LogNameAction extends Action {
  LogNameAction(this.name);

  final String name;
}

class NamesAndCountsBloc implements Bloc<ListAppState> {
  static const _names = ['Steve', 'Yu Yan', 'Sreela', 'Angelica', 'Guillaume'];
  static Random _rng = Random();

  Timer _timer;

  @override
  Stream<WareContext<ListAppState>> applyMiddleware(
      Stream<WareContext<ListAppState>> input) {
    input.listen((context) {
      if (context.action is StartStreamOfIncrementsAction) {
        _timer?.cancel();
        _timer = Timer.periodic(
            Duration(seconds: 3),
            (_) => context.dispatcher(
                IncrementAction(_names[_rng.nextInt(_names.length)])));
      }
    });

    return input;
  }

  @override
  Stream<Accumulator<ListAppState>> applyReducer(
      Stream<Accumulator<ListAppState>> input) {
    return input.map((accumulator) {
      if (accumulator.action is IncrementAction) {
        String name = (accumulator.action as IncrementAction).name;
        int newTotal = (accumulator.state.namesAndCounts[name] ?? 0) + 1;
        return Accumulator(
          accumulator.action,
          accumulator.state.copyWith({name: newTotal}),
        );
      }

      return accumulator;
    });
  }

  @override
  Stream<WareContext<ListAppState>> applyAfterware(
      Stream<WareContext<ListAppState>> input) {
    return input;
  }

  @override
  void dispose() {
    print('Disposing NamesAndCountsBloc!');
    _timer.cancel();
  }
}

class LoggerBloc extends SimpleBloc<ListAppState> {
  ListAppState lastState;

  @override
  Future<Action> middleware(dispatcher, state, action) async {
    if (action is LogNameAction) {
      print('New widget has appeared: ${action.name}.');
    }

    return action;
  }

  @override
  FutureOr<Action> afterware(
      DispatchFunction dispatcher, ListAppState state, Action action) {
    if (state != lastState) {
      print('State just became: $state');
      lastState = state;
    }

    return action;
  }
}

class NameAndCount extends StatelessWidget {
  final String name;

  const NameAndCount(this.name, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelSubscriber<ListAppState, int>(
      converter: (state) => state.namesAndCounts[name],
      builder: (context, dispatcher, viewModel) {
        final dateStr = formatTime(DateTime.now());

        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('$name', style: Theme.of(context).textTheme.headline),
                Text('Count: $viewModel'),
                Text('Rebuilt at $dateStr'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NameListViewModel {
  final List<String> names;

  const NameListViewModel(this.names);

  @override
  bool operator ==(dynamic other) {
    if (names.length != other.names.length) {
      return false;
    }

    for (int i = 0; i < names.length; i++) {
      if (names[i] != other.names[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode {
    return names.hashCode;
  }
}

class ListExamplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreProvider<ListAppState>(
      store: Store<ListAppState>(
        initialState: ListAppState.initialState(),
        blocs: [
          LoggerBloc(),
          NamesAndCountsBloc(),
        ],
      ),
      disposeStore: true,
      child: FirstBuildDispatcher<ListAppState>(
        action: StartStreamOfIncrementsAction(),
        child: ViewModelSubscriber<ListAppState, NameListViewModel>(
          converter: (state) =>
              NameListViewModel(state.namesAndCounts.keys.toList()),
          builder: (context, dispatcher, viewModel) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 16.0),
                  Text('Rebuilt at ${formatTime(DateTime.now())}'),
                  SizedBox(height: 16.0),
                  for (final name in viewModel.names)
                    FirstBuildDispatcher<ListAppState>(
                      action: LogNameAction(name),
                      child: NameAndCount(name, key: ValueKey(name)),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
