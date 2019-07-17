// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:example/simple.dart';
import 'package:flutter/material.dart' hide Action;

import 'list.dart';

void main() => runApp(ExampleApp());

class ExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Rebloc example'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Simple'),
                Tab(text: 'List'),
              ],
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: TabBarView(
              children: [
                SimpleExamplePage(),
                ListExamplePage(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
