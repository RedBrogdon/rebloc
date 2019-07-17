// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:example/simple.dart';
import 'package:test/test.dart';

void main() {
  group('IntBloc reduces correctly.', () {
    test('IntBloc increments correctly', () {
      const state = SimpleAppState(0, 1.0, 'XXX');
      final action = IntAction();
      final bloc = IntBloc();
      final result = bloc.reducer(state, action);
      expect(result.anInt, 1);
      expect(result.aDouble, 1.0);
      expect(result.aString, 'XXX');
    });
    test('IntBloc resets correctly', () {
      const state = SimpleAppState(1, 1.0, 'XXX');
      final action = ResetAction();
      final bloc = IntBloc();
      final result = bloc.reducer(state, action);
      expect(result.anInt, 0);
      expect(result.aDouble, 1.0);
      expect(result.aString, 'XXX');
    });
  });
}
