// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart' hide Action;
import 'package:rebloc/rebloc.dart';

import 'utils.dart';

class SimpleAppState {
  final int anInt;
  final double aDouble;
  final String aString;

  const SimpleAppState(this.anInt, this.aDouble, this.aString);

  const SimpleAppState.initialState()
      : anInt = 0,
        aDouble = 0.0,
        aString = "AAA";

  SimpleAppState copyWith({int anInt, double aDouble, String aString}) {
    return SimpleAppState(
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

class IntBloc extends SimpleBloc<SimpleAppState> {
  @override
  SimpleAppState reducer(state, action) {
    if (action is IntAction) {
      return state.copyWith(anInt: state.anInt + 1);
    } else if (action is ResetAction) {
      return state.copyWith(anInt: 0);
    }

    return state;
  }
}

class DoubleBloc extends SimpleBloc<SimpleAppState> {
  @override
  SimpleAppState reducer(state, action) {
    if (action is DoubleAction) {
      return state.copyWith(aDouble: state.aDouble + 1.0);
    } else if (action is ResetAction) {
      return state.copyWith(aDouble: 0.0);
    }

    return state;
  }
}

class StringBloc extends SimpleBloc<SimpleAppState> {
  @override
  SimpleAppState reducer(state, action) {
    if (action is StringAction) {
      return state.copyWith(aString: '${state.aString}${action.newChar}');
    } else if (action is ResetAction) {
      return state.copyWith(aString: 'AAA');
    }

    return state;
  }
}

class DescriptionBloc extends SimpleBloc<SimpleAppState> {
  @override
  FutureOr<Action> middleware(dispatcher, state, action) {
    if (action is DescriptionAction) {
      dispatcher(IntAction());
      dispatcher(DoubleAction());
      dispatcher(StringAction('B'));
    }

    return action;
  }
}

class LoggerBloc extends SimpleBloc<SimpleAppState> {
  SimpleAppState lastState;

  @override
  Future<Action> middleware(dispatcher, state, action) async {
    print('${action.runtimeType} dispatched.');

    // This is just to demonstrate that middleware can be async. In most cases,
    // you'll want to cancel or return immediately.
    return await Future.delayed(Duration.zero, () => action);
  }

  @override
  FutureOr<Action> afterware(
      DispatchFunction dispatcher, SimpleAppState state, Action action) {
    if (state != lastState) {
      print('State just became: $state');
      lastState = state;
    }

    return action;
  }
}

/// Limits each of the three values in [SimpleAppState] to certain maximums.
/// This [Bloc] must appear before the others in the list given to the [Store].
class LimitBloc extends SimpleBloc<SimpleAppState> {
  static const maxInt = 10;
  static const maxDouble = 10;
  static const maxLength = 10;

  @override
  FutureOr<Action> middleware(
      DispatchFunction dispatcher, SimpleAppState state, Action action) {
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
    return ViewModelSubscriber<SimpleAppState, int>(
      converter: (state) => state.anInt,
      builder: (context, dispatcher, viewModel) {
        final dateStr = formatTime(DateTime.now());

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
    return ViewModelSubscriber<SimpleAppState, double>(
      converter: (state) => state.aDouble,
      builder: (context, dispatcher, viewModel) {
        final dateStr = formatTime(DateTime.now());

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
    return ViewModelSubscriber<SimpleAppState, String>(
      converter: (state) => state.aString,
      builder: (context, dispatcher, viewModel) {
        final dateStr = formatTime(DateTime.now());

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

  DescriptionViewModel(SimpleAppState state)
      : description = state.toString() + "!";

  @override
  bool operator ==(dynamic other) {
    return description == other.description;
  }

  @override
  int get hashCode => description.hashCode;
}

class DescriptionDisplayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelSubscriber<SimpleAppState, DescriptionViewModel>(
      converter: (state) => DescriptionViewModel(state),
      builder: (context, dispatcher, viewModel) {
        final dateStr = formatTime(DateTime.now());

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
            ],
          ),
        );
      },
    );
  }
}

// Under normal circumstances, you probably wouldn't want to have a Store just
// hanging out as a top-level variable. It's being done here to make the point
// that you can have a long-lived Store somewhere in memory and use it with
// different StoreProvider widgets.
//
// The list example, on the other hand, creates a new Store each time that page
// is displayed, and tears down the Store when finished.
final _store = Store<SimpleAppState>(
  initialState: SimpleAppState.initialState(),
  blocs: [
    LoggerBloc(),
    LimitBloc(),
    IntBloc(),
    DoubleBloc(),
    StringBloc(),
    DescriptionBloc(),
  ],
);

class SimpleExamplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: StoreProvider<SimpleAppState>(
        store: _store,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListView(
            children: [
              SizedBox(height: 16.0),
              Text('Integer view model:', style: textTheme.subtitle1),
              IntDisplayWidget(),
              SizedBox(height: 24.0),
              Text('Double view model:', style: textTheme.subtitle1),
              DoubleDisplayWidget(),
              SizedBox(height: 24.0),
              Text('String view model:', style: textTheme.subtitle1),
              StringDisplayWidget(),
              SizedBox(height: 24.0),
              Text('Combined view model:', style: textTheme.subtitle1),
              DescriptionDisplayWidget(),
              DispatchSubscriber<SimpleAppState>(
                builder: (context, dispatcher) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    child: Text('Reset everything'),
                    onPressed: () => dispatcher(ResetAction()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
