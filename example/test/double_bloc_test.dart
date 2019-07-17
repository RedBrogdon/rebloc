// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:example/simple.dart';
import 'package:test/test.dart';

void main() {
  group('DoubleBloc reduces correctly.', () {
    test('DoubleBloc increments correctly', () {
      const state = SimpleAppState(1, 0.0, 'XXX');
      final action = DoubleAction();
      final bloc = DoubleBloc();
      final result = bloc.reducer(state, action);
      expect(result.anInt, 1);
      expect(result.aDouble, 1.0);
      expect(result.aString, 'XXX');
    });
    test('DoubleBloc resets correctly', () {
      const state = SimpleAppState(1, 1.0, 'XXX');
      final action = ResetAction();
      final bloc = DoubleBloc();
      final result = bloc.reducer(state, action);
      expect(result.anInt, 1);
      expect(result.aDouble, 0.0);
      expect(result.aString, 'XXX');
    });
  });
}
