import 'dart:async';

import 'package:shutdown/shutdown.dart' as shutdown;

Future main() async {
  shutdown.triggerOnSigInt();
  shutdown.triggerOnSigHup();

  final db = await _acquireDB();
  shutdown.addHandler(() => db.close());

  // [do you stuff]

  // call it at the end, this is a successful exit
  await shutdown.shutdown();
}

Future _acquireDB() async => null; // TODO: implement
