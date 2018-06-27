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
