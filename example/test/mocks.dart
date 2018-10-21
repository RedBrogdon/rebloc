// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:rebloc/rebloc.dart';

class MockStore {
  final actions = <Action>[];
  void dispatcher(Action action) => actions.add(action);
}
