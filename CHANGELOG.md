# Changelog

## [0.3.0-wip]

## [0.2.0] - 2026-08-08

### Changed

- Semantic conventions aligned with the current OTel registry: spans
  carry the registry `error.type` key on failures; command-specific
  keys (`command.name`, `command.system`, `command.result`) stay
  package-local because no registry convention for UI commands exists
  yet. No deprecated registry keys are emitted.
- Dependency floors raised to `dartastic_opentelemetry ^1.1.0-beta.12` and
  `dartastic_opentelemetry_api ^1.0.0-rc.1`. The previous floors declared
  compatibility with API versions that predate the semconv enums this
  package uses and could not actually resolve-and-compile.
- `repository` URL corrected to the canonical `Dartastic` org casing so
  pub.dev repository verification succeeds.

### Added

- `Command.runTraced(param, spanName)` — sync executor wrapped in
  a CLIENT-kind span. (Mirrors `command_it` 9.x's renamed
  `run` method; the old `execute` is deprecated upstream.)
- `Command.runAsyncTraced(param, spanName)` — async executor wrapped
  in a span; awaits the future before closing.
- Span shape: `command_it <name>` with `command.name`,
  `command.system=command_it`, `command.result` = `success` /
  `error`. Errors get `error.type` + `recordException` + `Error`
  status, then rethrow.
- Local `CommandItSemantics` enum (implements `OTelSemantic`).
- Zone-scoped suppression via `runWithoutCommandItInstrumentation()`
  / `Async()`.
- Six `flutter_test` tests instrumenting real `Command`s and asserting
  span shape via the SDK's `package:dartastic_opentelemetry/testing.dart`
  surface (no network).

### Design notes

- `command_it` is the renamed `flutter_command`; the API is the same
  except `execute` → `run` and `executeWithFuture` → `runAsync`.
  If you're on the legacy package, see
  [`otel_flutter_command`](https://pub.dev/packages/otel_flutter_command).
- We instrument at the call site (extension methods on `Command`)
  rather than via the package's global hooks for the same reasons
  documented in `otel_flutter_command` — the global `loggingHandler`
  fires only at end of execution (can't measure duration) and the
  per-command `results` notifier filters no-op updates by `==`
  (sync void commands emit no event at all).
- The async-throw path needs either a local error handler or a
  `Command.globalExceptionHandler` registered; otherwise `runAsync`
  rethrows synchronously and the future never completes. This is a
  property of `command_it` 9.x, not the wrapper.
