// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:example/simple.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';

import 'mocks.dart';

void main() {
  group('DescriptionBloc middleware performs correctly.', () {
    test('DescriptionBloc dispatches three correct actions', () async {
      const state = SimpleAppState(0, 0.0, 'AAA');
      final action = DescriptionAction();
      final bloc = DescriptionBloc();
      final store = MockStore();
      await bloc.middleware(store.dispatcher, state, action);
      expect(store.actions[0], TypeMatcher<IntAction>());
      expect(store.actions[1], TypeMatcher<DoubleAction>());
      expect(store.actions[2], TypeMatcher<StringAction>());
    });
    test('DescriptionBloc returns identical action', () async {
      const state = SimpleAppState(0, 0.0, 'AAA');
      final action = DescriptionAction();
      final bloc = DescriptionBloc();
      final store = MockStore();
      final result = await bloc.middleware(store.dispatcher, state, action);
      expect(result, same(action));
    });
  });
}
