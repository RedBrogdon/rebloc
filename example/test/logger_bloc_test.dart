// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:example/simple.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks.dart';

void main() {
  group('LoggerBloc middleware performs correctly.', () {
    test('LoggerBloc returns identical action', () async {
      const state = SimpleAppState(0, 0.0, 'AAA');
      final action = IntAction();
      final bloc = LoggerBloc();
      final store = MockStore();
      final result = await bloc.middleware(store.dispatcher, state, action);
      expect(result, same(action));
    });
  });
  group('LoggerBloc afterware performs correctly.', () {
    test('LoggerBloc returns identical action', () async {
      const state = SimpleAppState(0, 0.0, 'AAA');
      final action = IntAction();
      final bloc = LoggerBloc();
      final store = MockStore();
      final result = await bloc.afterware(store.dispatcher, state, action);
      expect(result, same(action));
    });
  });
}
