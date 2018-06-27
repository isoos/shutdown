# shutdown

Prioritized events for graceful shutdown in server Dart applications.

## Usage

A simple usage example:

````dart
import 'dart:async';

import 'package:shutdown/shutdown.dart' as shutdown;

Future main() async {
  shutdown.triggerOnSigInt();
  shutdown.triggerOnSigHup();

  final db = await _acquireDB();
  shutdown.addHandler(() => db.close());

  // [do your stuff]

  // call it at the end, this is a successful exit
  await shutdown.shutdown();
}

Future _acquireDB() async => null; // TODO: implement
````

## Tip

Combine this library with [package:stack_trace](https://pub.dartlang.org/packages/stack_trace):

````dart
import 'package:shutdown/shutdown.dart' as shutdown;
import 'package:stack_trace/stack_trace.dart';

Future main() async {
  shutdown.triggerOnSigInt();
  shutdown.triggerOnSigHup();
  return Chain.capture(() async {
    // TODO: initialize, register shutdown handlers
    // do your stuff
    await shutdown.shutdown();
  }, onError: (error, Chain chain) async {
    // TODO: report/log error and stack
    await shutdown.shutdown(exitCode: -1);
  });
}
````
