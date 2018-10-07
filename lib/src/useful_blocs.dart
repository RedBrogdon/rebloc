// Copyright 2018, The Flutter team
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:rebloc/rebloc.dart';
import 'package:rxdart/rxdart.dart';

class DebouncerBloc<T> implements Bloc<T> {
  DebouncerBloc(
    this.actions, {
    this.duration = const Duration(seconds: 1),
  })  : assert(duration != null),
        assert(actions != null),
        assert(actions.length > 0);

  final Duration duration;

  final List<Type> actions;

  @override
  Stream<MiddlewareContext<T>> applyMiddleware(
      Stream<MiddlewareContext<T>> input) {
    return MergeStream<MiddlewareContext<T>>([
      input.where((c) => !actions.contains(c.action.runtimeType)),
      Observable(input.where((c) => actions.contains(c.action.runtimeType)))
          .debounce(duration),
    ]);
  }

  @override
  Stream<Accumulator<T>> applyReducer(Stream<Accumulator<T>> input) {
    return input;
  }
}
