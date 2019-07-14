// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:rebloc/rebloc.dart';
import 'package:test/test.dart';

class IntState {
  final int anInt;

  const IntState(this.anInt);

  @override
  String toString() => 'IntState{$anInt)';
}

class IntStateMatcher extends Matcher {
  final IntState expectedState;

  const IntStateMatcher(this.expectedState);

  @override
  Description describe(Description description) {
    return description.add('is an IntState(${expectedState.anInt})');
  }

  @override
  bool matches(dynamic item, Map matchState) {
    return item is IntState && (expectedState.anInt == item.anInt);
  }
}

class IncrementAction extends Action {}

class SquareAction extends Action {}

class BasicBloc extends SimpleBloc<IntState> {
  @override
  IntState reducer(IntState state, Action action) {
    if (action is IncrementAction) {
      return IntState(state.anInt + 1);
    } else if (action is SquareAction) {
      return IntState(state.anInt * state.anInt);
    }

    return state;
  }
}

void main() {
  group('Store tests', () {
    test('Store with one bloc executes one action', () {
      final store = Store<IntState>(
        initialState: IntState(0),
        blocs: [
          BasicBloc(),
        ],
      );

      store.dispatch(IncrementAction());

      expect(
        store.states,
        emitsInOrder(<dynamic>[
          IntStateMatcher(IntState(0)),
          IntStateMatcher(IntState(1)),
        ]),
      );
    });

    test('Store with one bloc executes multiple identical actions', () {
      final store = Store<IntState>(
        initialState: IntState(0),
        blocs: [
          BasicBloc(),
        ],
      );

      store.dispatch(IncrementAction());
      store.dispatch(IncrementAction());
      store.dispatch(IncrementAction());

      expect(
        store.states,
        emitsInOrder(<dynamic>[
          IntStateMatcher(IntState(0)),
          IntStateMatcher(IntState(1)),
          IntStateMatcher(IntState(2)),
          IntStateMatcher(IntState(3)),
        ]),
      );
    });

    test('Store with one bloc executes multiple different actions', () {
      final store = Store<IntState>(
        initialState: IntState(0),
        blocs: [
          BasicBloc(),
        ],
      );

      store.dispatch(IncrementAction());
      store.dispatch(IncrementAction());
      store.dispatch(SquareAction());
      store.dispatch(IncrementAction());
      store.dispatch(SquareAction());

      expect(
        store.states,
        emitsInOrder(<dynamic>[
          IntStateMatcher(IntState(0)),
          IntStateMatcher(IntState(1)),
          IntStateMatcher(IntState(2)),
          IntStateMatcher(IntState(4)),
          IntStateMatcher(IntState(5)),
          IntStateMatcher(IntState(25)),
        ]),
      );
    });
  });
}
