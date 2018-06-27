import 'dart:async';
import 'dart:io';
import 'dart:isolate';

typedef FutureOr ShutdownHandler();
enum ShutdownType { isolate, vm }

class _Entry implements Comparable<_Entry> {
  final ShutdownHandler _handler;
  final int _priority;

  _Entry(this._handler, this._priority);

  @override
  int compareTo(_Entry other) {
    if (_priority == null && other._priority != null) return 1;
    if (_priority != null && other._priority == null) return -1;
    if (_priority != null &&
        other._priority != null &&
        _priority != other._priority) {
      return _priority.compareTo(other._priority);
    }
    return 0;
  }
}

final _entries = <_Entry>[];
final _signalSubscriptions = <StreamSubscription>[];

void registerDefaultProcessSignals({int exitCode}) {
  void process(ProcessSignal ps) {
    shutdown(type: ShutdownType.vm, exitCode: exitCode ?? -1);
  }

  _signalSubscriptions.add(ProcessSignal.sigint.watch().listen(process));
  _signalSubscriptions.add(ProcessSignal.sighup.watch().listen(process));
  _signalSubscriptions.add(ProcessSignal.sigkill.watch().listen(process));
}

void addShutdownHandler(ShutdownHandler handler, {int priority}) {
  _entries.add(new _Entry(handler, priority));
}

Future shutdown({ShutdownType type, int exitCode}) async {
  type ??= ShutdownType.vm;

  // TODO: sort on insert?
  _entries.sort();

  for (_Entry entry in _entries) {
    try {
      await entry._handler();
    } catch (e, st) {
      // TODO: error reporting with logging
      stderr.writeln('Shutdown handler error: $e\nStacktrace:\n$st');
    }
  }

  _signalSubscriptions.forEach((subs) => subs.cancel());

  switch (type) {
    case ShutdownType.isolate:
      Isolate.current.kill();
      break;
    default:
      exit(exitCode ?? 0);
      break;
  }
}
