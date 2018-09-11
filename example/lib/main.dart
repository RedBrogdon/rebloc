// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rebloc/rebloc.dart';

String _formatTime(DateTime time) {
  String hours = time.hour.toString().padLeft(2, '0');
  String minutes = time.minute.toString().padLeft(2, '0');
  String seconds = time.second.toString().padLeft(2, '0');
  String milliseconds = time.millisecond.toString().padLeft(3, '0');
  return '$hours:$minutes:$seconds.$milliseconds';
}

void main() => runApp(
      new MaterialApp(
        title: 'Rebloc Example',
        home: StoreProvider<AppState>(
          store: Store<AppState>(
            initialState: AppState.initialState(),
            blocs: [
              LoggerBloc(),
              LimitBloc(),
              IntBloc(),
              DoubleBloc(),
              StringBloc(),
              DescriptionBloc(),
            ],
          ),
          child: new MyHomePage(),
        ),
      ),
    );

class AppState {
  final int anInt;
  final double aDouble;
  final String aString;

  const AppState(this.anInt, this.aDouble, this.aString);

  const AppState.initialState()
      : anInt = 0,
        aDouble = 0.0,
        aString = "AAA";

  AppState copyWith({int anInt, double aDouble, String aString}) {
    return AppState(
      anInt ?? this.anInt,
      aDouble ?? this.aDouble,
      aString ?? this.aString,
    );
  }

  String toString() {
    return 'anInt is $anInt, aDouble is $aDouble, and aString is \'$aString\'';
  }
}

class IntAction extends Action {}

class DoubleAction extends Action {}

class StringAction extends Action {
  final String newChar;

  StringAction(this.newChar);
}

class DescriptionAction extends Action {}

class ResetAction extends Action {}

class IntBloc extends SimpleBloc<AppState> {
  @override
  AppState reducer(state, action) {
    if (action is IntAction) {
      return state.copyWith(anInt: state.anInt + 1);
    } else if (action is ResetAction) {
      return state.copyWith(anInt: 0);
    }

    return state;
  }
}

class DoubleBloc extends SimpleBloc<AppState> {
  @override
  AppState reducer(state, action) {
    if (action is DoubleAction) {
      return state.copyWith(aDouble: state.aDouble + 1.0);
    } else if (action is ResetAction) {
      return state.copyWith(aDouble: 0.0);
    }

    return state;
  }
}

class StringBloc extends SimpleBloc<AppState> {
  @override
  AppState reducer(state, action) {
    if (action is StringAction) {
      return state.copyWith(aString: '${state.aString}${action.newChar}');
    } else if (action is ResetAction) {
      return state.copyWith(aString: 'AAA');
    }

    return state;
  }
}

class DescriptionBloc extends SimpleBloc<AppState> {
  @override
  Action middleware(dispatcher, state, action) {
    if (action is DescriptionAction) {
      dispatcher(IntAction());
      dispatcher(DoubleAction());
      dispatcher(StringAction('B'));
    }

    return action;
  }
}

/// Logs each incoming action.
class LoggerBloc extends SimpleBloc<AppState> {
  @override
  Future<Action> middleware(dispatcher, state, action) async {
    print('${action.runtimeType} dispatched. State: $state.');

    // This is just to demonstrate that middleware can be async. In most cases,
    // you'll want to cancel or return immediately.
    return await Future.delayed(Duration.zero, () => action);
  }
}

/// Limits each of the three values in [AppState] to certain maximums. This
/// [Bloc] must appear before the others in the list given to the [Store].
class LimitBloc extends SimpleBloc<AppState> {
  static const maxInt = 10;
  static const maxDouble = 10;
  static const maxLength = 10;

  @override
  Action middleware(
      DispatchFunction dispatcher, AppState state, Action action) {
    if ((action is IntAction && state.anInt == maxInt) ||
        (action is DoubleAction && state.aDouble == maxDouble) ||
        (action is StringAction && state.aString.length == maxLength)) {
      // Cancel (or "swallow") the action if a limit would be exceeded.
      return Action.cancelled();
    }

    return action;
  }
}

class IntDisplayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelSubscriber<AppState, int>(
      converter: (state) => state.anInt,
      builder: (context, dispatcher, viewModel) {
        final dateStr = _formatTime(DateTime.now());

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Value: $viewModel'),
              Text('Rebuilt at $dateStr'),
              SizedBox(height: 4.0),
              RaisedButton(
                child: Text('Increment'),
                onPressed: () => dispatcher(IntAction()),
              )
            ],
          ),
        );
      },
    );
  }
}

class DoubleDisplayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelSubscriber<AppState, double>(
      converter: (state) => state.aDouble,
      builder: (context, dispatcher, viewModel) {
        final dateStr = _formatTime(DateTime.now());

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Value: $viewModel'),
              Text('Rebuilt at $dateStr'),
              SizedBox(height: 4.0),
              RaisedButton(
                child: Text('Increment'),
                onPressed: () => dispatcher(DoubleAction()),
              )
            ],
          ),
        );
      },
    );
  }
}

class StringDisplayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelSubscriber<AppState, String>(
      converter: (state) => state.aString,
      builder: (context, dispatcher, viewModel) {
        final dateStr = _formatTime(DateTime.now());

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Value: $viewModel'),
              Text('Rebuilt at $dateStr'),
              SizedBox(height: 4.0),
              RaisedButton(
                child: Text('Increment'),
                onPressed: () => dispatcher(StringAction('A')),
              )
            ],
          ),
        );
      },
    );
  }
}

class DescriptionViewModel {
  final String description;

  DescriptionViewModel(AppState state) : description = state.toString() + "!";

  @override
  bool operator ==(other) {
    return description == other.description;
  }

  @override
  int get hashCode => description.hashCode;
}

class DescriptionDisplayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelSubscriber<AppState, DescriptionViewModel>(
      converter: (state) => DescriptionViewModel(state),
      builder: (context, dispatcher, viewModel) {
        final dateStr = _formatTime(DateTime.now());

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Value: ${viewModel.description}'),
              Text('Rebuilt at $dateStr'),
              SizedBox(height: 4.0),
              RaisedButton(
                child: Text('Increment everything'),
                onPressed: () => dispatcher(DescriptionAction()),
              ),
              SizedBox(height: 8.0),
              RaisedButton(
                child: Text('Reset everything'),
                onPressed: () => dispatcher(ResetAction()),
              )
            ],
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Rebloc example')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Integer view model:', style: textTheme.subhead),
              IntDisplayWidget(),
              SizedBox(height: 24.0),
              Text('Double view model:', style: textTheme.subhead),
              DoubleDisplayWidget(),
              SizedBox(height: 24.0),
              Text('String view model:', style: textTheme.subhead),
              StringDisplayWidget(),
              SizedBox(height: 24.0),
              Text('Combined view model:', style: textTheme.subhead),
              DescriptionDisplayWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
