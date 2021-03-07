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

/// Debounces repeated dispatches of an [Action] or list of Actions.
///
/// This [Bloc] attaches directly to the middleware stream and uses RxDart's
/// [debounce] method to debounce [Action]s with runtime types contained in
/// [actionTypes] for the given [duration].
class DebouncerBloc<T> implements Bloc<T> {
  DebouncerBloc(
    this.actionTypes, {
    this.duration = const Duration(seconds: 1),
  }) : assert(actionTypes.isNotEmpty);

  /// The duration to use when debouncing.
  final Duration duration;

  /// The runtime types of Actions to be debounced. All other actions will pass
  /// through without interference.
  final List<Type> actionTypes;

  @override
  Stream<WareContext<T>> applyMiddleware(Stream<WareContext<T>> input) {
    // This rather complicated-looking statement splits the incoming stream of
    // Actions into two streams. Actions that match the types in [actionTypes]
    // go into one, and all other actions go into the other. The stream that
    // contains the matching actions is then debounced using the provided
    // Duration.
    return MergeStream<WareContext<T>>([
      input.where((c) => !actionTypes.contains(c.action.runtimeType)),
      input
          .where((c) => actionTypes.contains(c.action.runtimeType))
          .debounceTime(duration),
    ]);
  }

  @override
  Stream<Accumulator<T>> applyReducer(Stream<Accumulator<T>> input) {
    // This Bloc makes no changes to app state.
    return input;
  }

  @override
  Stream<WareContext<T>> applyAfterware(Stream<WareContext<T>> input) {
    // This Bloc takes no action after reducing is complete.
    return input;
  }

  @override
  void dispose() {
    // Nothing to dispose here.
  }
}
