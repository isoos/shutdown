import 'dart:async';
import 'dart:io';
import 'dart:isolate';

typedef ShutdownHandler = FutureOr Function();
enum ShutdownType { isolate, vm }

class _Entry implements Comparable<_Entry> {
  final ShutdownHandler _handler;
  final int _priority;
  final Duration _timeout;

  _Entry(this._handler, this._priority, this._timeout);

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

void addHandler(ShutdownHandler handler, {int priority, Duration timeout}) {
  _entries.add(_Entry(handler, priority, timeout));
}

bool _shutdownStarted = false;

/// Executes the registered handler in (a) increasing priority order
/// (unspecified priorities go to the end) and if that matches (b) in the order
/// they were added.
Future shutdown({
  ShutdownType type,
  int exitCode,
  Duration handlerTimeout = const Duration(seconds: 30),
  Duration overallTimeout = const Duration(minutes: 5),
  bool reverse = false,
}) async {
  type ??= ShutdownType.vm;

  if (_shutdownStarted) return;
  _shutdownStarted = true;

  Timer(overallTimeout, () {
    _kill(type, exitCode);
  });

  _signalSubscriptions.forEach((subs) => subs.cancel());

  _entries.sort();
  final entries = reverse ? _entries.reversed.toList() : _entries;

  for (final entry in entries) {
    try {
      final f = entry._handler();
      if (f is Future) {
        await f.timeout(entry._timeout ?? handlerTimeout,
            onTimeout: () => null);
      } else {
        await f;
      }
    } catch (e, st) {
      // TODO: error reporting with logging
      stderr.writeln('Shutdown handler error: $e\nStacktrace:\n$st');
    }
  }

  _kill(type, exitCode);
}

void _kill(ShutdownType type, int exitCode) {
  switch (type) {
    case ShutdownType.isolate:
      Isolate.current.kill();
      break;
    default:
      exit(exitCode ?? 0);
      break;
  }
}
