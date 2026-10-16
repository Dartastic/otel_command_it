<!-- dartastic-header:start -->
# OpenTelemetry instrumentation for `command_it`

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![OpenTelemetry Specification](https://img.shields.io/badge/OpenTelemetry-Specification-blueviolet)](https://opentelemetry.io/docs/specs/otel/)

`otel_command_it` is an [OpenTelemetry](https://opentelemetry.io/) instrumentation for `command_it` that
easily adds standard observability to applications that use `command_it`.  This package depends on 
[dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api).

This package can be used with any OTel backend because it's compliant with the OpenTelemetry Specification.

This package supports Android, iOS, Linux, macOS, Web and Windows, for versions of `command_it` that support those platforms. It is WASM-ready.

This Apache-2.0 package is professionally maintained and supported with 💙 by Michael Bushe,
Dart and Flutter Maintainer at OpenTelemetry and the creator of [dartastic_opentelemetry](https://pub.dev/packages/dartastic_opentelemetry)
and [dartastic_opentelemetry_api](https://pub.dev/packages/dartastic_opentelemetry_api). This package is professionally supported by
[Dartastic.io](https://dartastic.io).

---
## Dartastic.io: AI Code Healing and Real User Monitoring for Flutter

**See what your users experience. Find problems with Flutter apps in production. Fix them with AI.**

[Dartastic.io](https://dartastic.io) brings AI code healing, real user monitoring, and OpenTelemetry observability together in one platform built for Dart and Flutter. (Patents pending)

![Dartastic AI answering "Why did crashes jump after the last release?" over a Flutter App Health dashboard](https://dartastic.io/img/pub-dev/HomePageCrashesQuestion.png)

### Dartastic AI — From Production Problems to Code Fixes

Dartastic AI analyzes production telemetry alongside your application source code to diagnose problems and propose fixes.

- **Investigate production issues** using crashes, errors, traces, metrics, and real user telemetry.
- **Find the offending code** by connecting observed problems with your application's source in Dartastic Pub or your source code repos.
- **Generate code patches** that address the underlying problems.
- **Create actionable issues** in your issue tracker, complete with findings and the proposed code patch.

### Dartastic RUM — See What Your Users See

Understand how people actually experience your Flutter application.

- **Replay user sessions** in the Dartastic Observatory session player.
- **Choose your replay fidelity**, from privacy-preserving widget outlines to pixel-level reproductions of the user experience.
- **Investigate real user problems** using session replay and production observability data.

![Dartastic RUM Session Replay](https://dartastic.io/img/pub-dev/session-replay.png)

### Dartastic Observatory — Observability Built for Flutter

A complete observability backend where Flutter and Dart are first-class citizens.

- **Flutter-specific dashboards** for application performance, health, and reliability.
- **Alerts and notifications** through email, Slack, and PagerDuty.
- **Dartastic Cloud Observatory** — Start with a 30-day free trial on isolated, shared infrastructure, as low as $39/mo.
- **Dartastic Hosted Observatory** — Run the observability stack in a private managed environment, sized from Mini to Enterprise XL.
- **Dartastic Self-Hosted Observatory** — The whole platform inside your own network. Your keys, your cluster, with nothing leaving your perimeter.

### Dartastic Native OTel Runtime — Native OpenTelemetry Performance

Collect production telemetry without burdening Flutter's main isolate.

- **Native OpenTelemetry runtime** that moves telemetry processing off the main isolate.
- **Native crash reporting** for problems that Dart can't catch.
- **Widget performance diagnostics** to identify janky widgets.
- **On-device PII filtering** before sensitive data leaves your application.
- **Source-level error diagnostics** powered by the Dartastic Symbolizer API.
- **Platform-native metrics** for iOS, Android, and Linux, including iOS MetricKit and Android Vitals.
- **OpenTelemetry compatibility** — Send telemetry to Dartastic Observatory or any OpenTelemetry platform.

### Dartastic Labs — OpenTelemetry Integrations

Instrument more of your application without writing everything yourself.

- **650+ open-source integrations** for Dart and Flutter libraries and services, including Dio, Shelf, Logger, Anthropic, AWS, Azure, and Stripe. Look for otel_* on pub.dev.

### More Dartastic Tools

**[Dartastic Pub](https://dartastic.io/pub)**

A private Dart package registry for sharing packages and plugins with your team, partners, and customers.

**[Dartastic Symbolizer](https://dartastic.io/symbolizer)**

Turn production errors into lines of source code through a web API, while keeping your source code artifacts private.

### Professional Support and Training

Dartastic.io offers commercial support for the open-source `dartastic_opentelemetry` and `dartastic_opentelemetry_api` packages and the complete Dartastic product suite.

- **Professional support** with available around-the-clock coverage and response times under four hours on qualifying plans.
- **OpenTelemetry training** for teams instrumenting Dart, Flutter, mobile, and web applications.

### Open Standards. No Mandatory Backend.

The Dartastic OpenTelemetry API and SDK are open source and standards-based. You can use them independently of Dartastic's commercial services and send telemetry to any compatible OpenTelemetry backend.

Dartastic's commercial products add native performance, advanced diagnostics, session replay, AI-assisted remediation, and managed observability services.

**[Explore Dartastic.io](https://dartastic.io)**

---
<!-- dartastic-header:end -->

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
  otel_command_it: ^0.3.1
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
