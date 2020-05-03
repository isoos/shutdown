## 0.4.2

- Added `reverse` flag to triggers.

## 0.4.1

- Updated to latest Dart language lints.
- Added `reverse` flag to optionally execute handlers in reverse order.

## 0.4.0

- Enable Dart2 versions.
- Handler-specific and overall timeouts for closing resources.

## 0.3.0

**Breaking changes**

The suggested way is to use `shutdown` prefix when using the package, methods were renamed accordingly:

  - `addShutdownHandler` -> `addHandler`
  - `registerDefaultProcessSignals` -> `triggerOnSigInt` (and similar ones)

## 0.2.0

- Initial version: basic priorities.
- OS signal hooks.
