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

void _trigger(ProcessSignal signal, int exitCode) {
  _signalSubscriptions.add(signal.watch().listen((_) {
    shutdown(type: ShutdownType.vm, exitCode: exitCode ?? -1);
  }));
}

void triggerOnSignal(ProcessSignal signal, {int exitCode}) =>
    _trigger(signal, exitCode);

void triggerOnSigInt({int exitCode}) =>
    _trigger(ProcessSignal.sigint, exitCode);

void triggerOnSigHup({int exitCode}) =>
    _trigger(ProcessSignal.sighup, exitCode);

void triggerOnSigKill({int exitCode}) =>
    _trigger(ProcessSignal.sigkill, exitCode);

void addHandler(ShutdownHandler handler, {int priority}) {
  _entries.add(new _Entry(handler, priority));
}

bool _shutdownStarted = false;

Future shutdown({ShutdownType type, int exitCode}) async {
  if (_shutdownStarted) return;
  _shutdownStarted = true;

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
