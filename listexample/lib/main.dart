// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rebloc/rebloc.dart';

String _formatTime(DateTime time) {
  String hours = time.hour.toString().padLeft(2, '0');
  String minutes = time.minute.toString().padLeft(2, '0');
  String seconds = time.second.toString().padLeft(2, '0');
  String milliseconds = time.millisecond.toString().padLeft(3, '0');
  return '$hours:$minutes:$seconds.$milliseconds';
}

void main() {
  final store = Store<AppState>(
    initialState: AppState.initialState(),
    blocs: [
      LoggerBloc(),
      NamesAndCountsBloc(),
    ],
  );

  runApp(
    new MaterialApp(
      title: 'Rebloc List Example',
      home: StoreProvider<AppState>(
        store: store,
        child: new MyHomePage(),
      ),
    ),
  );

  store.dispatcher(StartStreamOfIncrementsAction());
}

class AppState {
  final Map<String, int> namesAndCounts;

  const AppState(this.namesAndCounts);

  const AppState.initialState()
      : namesAndCounts = const {
          'Steve': 1,
        };

  AppState copyWith(Map<String, int> newData) {
    return AppState(Map.from(this.namesAndCounts)..addAll(newData));
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

class NamesAndCountsBloc implements Bloc<AppState> {
  static const _names = ['Steve', 'Yu Yan', 'Sreela', 'Angelica', 'Guillaume'];
  static Random _rng = Random();

  // A reference needs to be held here so the Timer doesn't get GCed. It's used
  // to send periodic increment actions out.
  // ignore: unused_field
  Timer _timer;

  @override
  Stream<WareContext<AppState>> applyMiddleware(
      Stream<WareContext<AppState>> input) {
    input.listen((context) {
      if (context.action is StartStreamOfIncrementsAction) {
        _timer = Timer.periodic(
            Duration(seconds: 3),
            (_) => context.dispatcher(
                IncrementAction(_names[_rng.nextInt(_names.length)])));
      }
    });

    return input;
  }

  @override
  Stream<Accumulator<AppState>> applyReducer(
      Stream<Accumulator<AppState>> input) {
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
  Stream<WareContext<AppState>> applyAfterware(
      Stream<WareContext<AppState>> input) {
    return input;
  }
}

class LoggerBloc extends SimpleBloc<AppState> {
  AppState lastState;

  @override
  Future<Action> middleware(dispatcher, state, action) async {
    if (action is LogNameAction) {
      print('New widget has appeared: ${action.name}.');
    }

    return action;
  }

  @override
  FutureOr<Action> afterware(
      DispatchFunction dispatcher, AppState state, Action action) {
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
    return ViewModelSubscriber<AppState, int>(
      converter: (state) => state.namesAndCounts[name],
      builder: (context, dispatcher, viewModel) {
        final dateStr = _formatTime(DateTime.now());

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
  bool operator ==(other) {
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

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rebloc list example')),
      body: ViewModelSubscriber<AppState, NameListViewModel>(
        converter: (state) =>
            NameListViewModel(state.namesAndCounts.keys.toList()),
        builder: (context, dispatcher, viewModel) {
          final dateStr = _formatTime(DateTime.now());

          final listRows = viewModel.names.map<Widget>((name) {
            return FirstBuildDispatcher<AppState>(
              action: LogNameAction(name),
              child: NameAndCount(name, key: ValueKey(name)),
            );
          });

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16.0),
                Text('Rebuilt at $dateStr'),
                SizedBox(height: 16.0),
              ]..addAll(listRows),
            ),
          );
        },
      ),
    );
  }
}
