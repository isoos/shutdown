# shutdown

Prioritized events for graceful shutdown in server Dart applications.

## Usage

A simple usage example:

````dart
import 'dart:async';

import 'package:shutdown/shutdown.dart';

Future main() async {
  registerDefaultProcessSignals();

  final db = await _acquireDB();
  addShutdownHandler(() => db.close());

  // [do you stuff]

  // call it at the end, this is a successful exit
  await shutdown();
}

Future _acquireDB() async => null; // TODO: implement
````

## Tip

Combine this library with [package:stack_trace](https://pub.dartlang.org/packages/stack_trace):

````dart
import 'package:shutdown/shutdown.dart';
import 'package:stack_trace/stack_trace.dart';

Future main() async {
  registerDefaultProcessSignals();
  return Chain.capture(() async {
    // TODO: initialize, register shutdown handlers
    // do your stuff
    await shutdown();
  }, onError: (error, Chain chain) async {
    // TODO: report/log error and stack
    await shutdown(exitCode: -1);
  });
}
````
