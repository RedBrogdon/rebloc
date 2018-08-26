// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:rebloc/rebloc.dart';
import 'package:intl/intl.dart';

void main() => runApp(new MyApp());

final dateFmt = DateFormat.Hms();

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
    return 'anInt is $anInt, aDouble is $aDouble, and aString is \'$aString\'.';
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Rebloc Example',
      home: StoreProvider<AppState>(
        store: Store<AppState>(
          initialState: AppState.initialState(),
          blocs: [
            LoggerBloc(),
            IntBloc(),
            DoubleBloc(),
            StringBloc(),
            DescriptionBloc(),
          ],
        ),
        child: new MyHomePage(),
      ),
    );
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
  ReducerFunction<AppState> get reducer => (state, action) {
        if (action is IntAction) {
          return state.copyWith(anInt: state.anInt + 1);
        } else if (action is ResetAction) {
          return state.copyWith(anInt: 0);
        }

        return state;
      };
}

class DoubleBloc extends SimpleBloc<AppState> {
  @override
  ReducerFunction<AppState> get reducer => (state, action) {
        if (action is DoubleAction) {
          return state.copyWith(aDouble: state.aDouble + 1.0);
        } else if (action is ResetAction) {
          return state.copyWith(aDouble: 0.0);
        }

        return state;
      };
}

class StringBloc extends SimpleBloc<AppState> {
  @override
  ReducerFunction<AppState> get reducer => (state, action) {
        if (action is StringAction) {
          return state.copyWith(aString: '${state.aString}${action.newChar}');
        } else if (action is ResetAction) {
          return state.copyWith(aString: 'AAA');
        }

        return state;
      };
}

class DescriptionBloc extends SimpleBloc<AppState> {
  @override
  MiddlewareFunction<AppState> get middleware => (dispatcher, state, action) {
        if (action is DescriptionAction) {
          dispatcher(IntAction());
          dispatcher(DoubleAction());
          dispatcher(StringAction('B'));
        }

        return action;
      };
}

class LoggerBloc extends SimpleBloc<AppState> {
  @override
  MiddlewareFunction<AppState> get middleware => (dispatcher, state, action) {
        print('${action.runtimeType} dispatched. State: $state.');
        return action;
      };
}

class IntViewModel extends ViewModel<AppState> {
  final int anInt;

  IntViewModel(DispatchFunction dispatcher, AppState state)
      : anInt = state.anInt,
        super(dispatcher);

  @override
  bool operator ==(other) {
    return anInt == other.anInt;
  }

  @override
  int get hashCode => anInt.hashCode;
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
          Text('Rebuilt: $dateStr'),
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

class DoubleViewModel extends ViewModel<AppState> {
  final double aDouble;

  DoubleViewModel(DispatchFunction dispatcher, AppState state)
      : aDouble = state.aDouble,
        super(dispatcher);

  @override
  bool operator ==(other) {
    return aDouble == other.aDouble;
  }

  @override
  int get hashCode => aDouble.hashCode;
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
          Text('Rebuilt: $dateStr'),
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

class StringViewModel extends ViewModel<AppState> {
  final String aString;

  StringViewModel(DispatchFunction dispatcher, AppState state)
      : aString = state.aString,
        super(dispatcher);

  @override
  bool operator ==(other) {
    return aString == other.aString;
  }

  @override
  int get hashCode => aString.hashCode;
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
          Text('Rebuilt: $dateStr'),
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

class DescriptionViewModel extends ViewModel<AppState> {
  final String description;

  DescriptionViewModel(DispatchFunction dispatcher, AppState state)
      : description = state.toString(),
        super(dispatcher);

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
          Text('Rebuilt: $dateStr'),
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
              ViewModelSubscriber<AppState, IntViewModel>(
                converter: (dispatcher, state) =>
                    IntViewModel(dispatcher, state),
                builder: (context, viewModel) {
                  return IntWidget(
                    anInt: viewModel.anInt,
                    onIncrement: () => viewModel.dispatcher(IntAction()),
                  );
                },
              ),
              SizedBox(height: 24.0),
              Text('Double view model:', style: textTheme.subhead),
              ViewModelSubscriber<AppState, DoubleViewModel>(
                converter: (dispatcher, state) =>
                    DoubleViewModel(dispatcher, state),
                builder: (context, viewModel) {
                  return DoubleWidget(
                    aDouble: viewModel.aDouble,
                    onIncrement: () => viewModel.dispatcher(DoubleAction()),
                  );
                },
              ),
              SizedBox(height: 24.0),
              Text('String view model:', style: textTheme.subhead),
              ViewModelSubscriber<AppState, StringViewModel>(
                converter: (dispatcher, state) =>
                    StringViewModel(dispatcher, state),
                builder: (context, viewModel) {
                  return StringWidget(
                    aString: viewModel.aString,
                    onIncrement: () => viewModel.dispatcher(StringAction('A')),
                  );
                },
              ),
              SizedBox(height: 24.0),
              Text('Combined view model:', style: textTheme.subhead),
              ViewModelSubscriber<AppState, DescriptionViewModel>(
                converter: (dispatcher, state) =>
                    DescriptionViewModel(dispatcher, state),
                builder: (context, viewModel) {
                  return DescriptionWidget(
                    description: viewModel.description,
                    onIncrement: () =>
                        viewModel.dispatcher(DescriptionAction()),
                    onReset: () => viewModel.dispatcher(ResetAction()),
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
