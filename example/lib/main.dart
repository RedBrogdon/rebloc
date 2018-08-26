// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rebloc/rebloc.dart';
import 'package:intl/intl.dart';

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

final dateFmt = DateFormat.jms();

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

  const StringAction(this.newChar);
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
/// [Bloc] must appear before the others in the [List] given to [Store].
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
      // Cancel (or "swallow") the action.
      return Action.cancelled();
    }

    return action;
  }
}

class IntWidget extends StatelessWidget {
  final int anInt;
  final VoidCallback onIncrement;

  const IntWidget({this.anInt, this.onIncrement});

  @override
  Widget build(BuildContext context) {
    final dateStr = dateFmt.format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Value: $anInt'),
          Text('Rebuilt at $dateStr'),
          SizedBox(height: 4.0),
          RaisedButton(
            child: Text('Increment'),
            onPressed: onIncrement,
          )
        ],
      ),
    );
  }
}

class DoubleWidget extends StatelessWidget {
  final double aDouble;
  final VoidCallback onIncrement;

  const DoubleWidget({this.aDouble, this.onIncrement});

  @override
  Widget build(BuildContext context) {
    final dateStr = dateFmt.format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Value: $aDouble'),
          Text('Rebuilt at $dateStr'),
          SizedBox(height: 4.0),
          RaisedButton(
            child: Text('Increment'),
            onPressed: onIncrement,
          )
        ],
      ),
    );
  }
}

class StringWidget extends StatelessWidget {
  final String aString;
  final VoidCallback onIncrement;

  const StringWidget({this.aString, this.onIncrement});

  @override
  Widget build(BuildContext context) {
    final dateStr = dateFmt.format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Value: $aString'),
          Text('Rebuilt at $dateStr'),
          SizedBox(height: 4.0),
          RaisedButton(
            child: Text('Increment'),
            onPressed: onIncrement,
          )
        ],
      ),
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

class DescriptionWidget extends StatelessWidget {
  final String description;
  final VoidCallback onIncrement;
  final VoidCallback onReset;

  const DescriptionWidget({this.description, this.onIncrement, this.onReset});

  @override
  Widget build(BuildContext context) {
    final dateStr = dateFmt.format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Value: $description'),
          Text('Rebuilt at $dateStr'),
          SizedBox(height: 4.0),
          RaisedButton(
            child: Text('Increment everything'),
            onPressed: onIncrement,
          ),
          SizedBox(height: 8.0),
          RaisedButton(
            child: Text('Reset everything'),
            onPressed: onReset,
          )
        ],
      ),
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
              ViewModelSubscriber<AppState, int>(
                converter: (state) => state.anInt,
                builder: (context, dispatcher, viewModel) {
                  return IntWidget(
                    anInt: viewModel,
                    onIncrement: () => dispatcher(IntAction()),
                  );
                },
              ),
              SizedBox(height: 24.0),
              Text('Double view model:', style: textTheme.subhead),
              ViewModelSubscriber<AppState, double>(
                converter: (state) => state.aDouble,
                builder: (context, dispatcher, viewModel) {
                  return DoubleWidget(
                    aDouble: viewModel,
                    onIncrement: () => dispatcher(DoubleAction()),
                  );
                },
              ),
              SizedBox(height: 24.0),
              Text('String view model:', style: textTheme.subhead),
              ViewModelSubscriber<AppState, String>(
                converter: (state) => state.aString,
                builder: (context, dispatcher, viewModel) {
                  return StringWidget(
                    aString: viewModel,
                    onIncrement: () => dispatcher(StringAction('A')),
                  );
                },
              ),
              SizedBox(height: 24.0),
              Text('Combined view model:', style: textTheme.subhead),
              ViewModelSubscriber<AppState, DescriptionViewModel>(
                converter: (state) => DescriptionViewModel(state),
                builder: (context, dispatcher, viewModel) {
                  return DescriptionWidget(
                    description: viewModel.description,
                    onIncrement: () => dispatcher(DescriptionAction()),
                    onReset: () => dispatcher(ResetAction()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
