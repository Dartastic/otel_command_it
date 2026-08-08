# otel_command_it

OpenTelemetry instrumentation for
[`package:command_it`](https://pub.dev/packages/command_it) —
Thomas Burkhart's `Command` pattern for Flutter UI actions
(renamed from `flutter_command` at v9.0).

Adds a CLIENT-kind span around every command execution so you can see
exactly which button taps / form submits / refresh handlers are slow
and which ones throw.

## Install

```yaml
dependencies:
  command_it: ^9.0.0
  otel_command_it: ^0.2.0
```

If you're still on the legacy package, use
[`otel_flutter_command`](https://pub.dev/packages/otel_flutter_command)
instead.

## Use

Replace `.run(...)` with `.runTraced(...)` and `.runAsync(...)` with
`.runAsyncTraced(...)`:

```dart
import 'package:command_it/command_it.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_command_it/otel_command_it.dart';

// Define a command, as usual.
final saveNote = Command.createAsyncNoResult<String>(
  (text) async { await db.save(text); },
);

// In your button handler:
ElevatedButton(
  onPressed: () => saveNote.runAsyncTraced(
    textController.text,
    'saveNote',
  ),
  child: const Text('Save'),
);
```

For sync commands:

```dart
final clearForm = Command.createSyncNoParamNoResult(() {
  textController.clear();
});

ElevatedButton(
  onPressed: () => clearForm.runTraced(null, 'clearForm'),
  child: const Text('Clear'),
);
```

## Span shape

| Attribute        | Source                                              |
|------------------|-----------------------------------------------------|
| `command.name`   | the `spanName` you pass (defaults to `<anonymous>`) |
| `command.system` | hardcoded `command_it`                              |
| `command.result` | `success` or `error`                                |
| `error.type`     | exception class on throw                            |

Span name: `command_it <spanName>`.

The span captures the full duration of:
- `runTraced` — from call until `run(...)` returns (or throws).
  For async commands this is just the synchronous dispatch; use
  `runAsyncTraced` for the awaited duration.
- `runAsyncTraced` — from call until the underlying `Future`
  completes (success or error).

## Why call-site instrumentation?

`command_it` ships two global hooks:

- `Command.loggingHandler` — fires once at the end of execution.
  Can't measure duration.
- `Command.globalExceptionHandler` — fires when an exception
  escapes a command. Can't measure duration either.

And the per-command `results` `ValueListenable` filters out no-op
updates with `==`. So a `createSyncNoParamNoResult` command (whose
result type is `void`) emits *no* result events at all when run,
because the new `CommandResult` compares equal to the initial one.

Call-site instrumentation sidesteps both issues.

## Note on async errors

For the `runAsyncTraced` error path to complete properly, `command_it`
9.x requires either a local error handler on the command or a global
`Command.globalExceptionHandler`. Without one, `runAsync` rethrows
synchronously and the future never resolves. Set a global handler
once at app startup — even a no-op `(cmd, err) {}` — to keep all
async commands well-behaved.

## Suppression

```dart
await runWithoutCommandItInstrumentationAsync(() async {
  await myCommand.runAsyncTraced(p, 'hot.path');  // skipped
});
```

## See also

- [`otel_flutter_command`](https://pub.dev/packages/otel_flutter_command) —
  the legacy package wrapper (same API as command_it 8.x).
- [`otel_get_it`](https://pub.dev/packages/otel_get_it) — Thomas
  Burkhart's service locator.
- [`otel_watch_it`](https://pub.dev/packages/otel_watch_it) —
  Thomas Burkhart's Flutter binding to `get_it`.

## License

Apache 2.0 — copyright Mindful Software LLC.
