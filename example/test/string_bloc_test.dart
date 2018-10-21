// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:example/main.dart';
import 'package:test/test.dart';

void main() {
  group('StringBloc reduces correctly.', () {
    test('StringBloc increments correctly', () {
      const state = AppState(1, 1.0, 'XXX');
      final action = StringAction('B');
      final bloc = StringBloc();
      final result = bloc.reducer(state, action);
      assert(result.anInt == 1 &&
          result.aDouble == 1.0 &&
          result.aString == 'XXXB');
    });
    test('StringBloc resets correctly', () {
      const state = AppState(1, 1.0, 'XXX');
      final action = ResetAction();
      final bloc = StringBloc();
      final result = bloc.reducer(state, action);
      assert(result.anInt == 1 &&
          result.aDouble == 1.0 &&
          result.aString == 'AAA');
    });
  });
}
