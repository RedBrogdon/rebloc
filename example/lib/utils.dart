// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String formatTime(DateTime time) {
  String hours = time.hour.toString().padLeft(2, '0');
  String minutes = time.minute.toString().padLeft(2, '0');
  String seconds = time.second.toString().padLeft(2, '0');
  String milliseconds = time.millisecond.toString().padLeft(3, '0');
  return '$hours:$minutes:$seconds.$milliseconds';
}
