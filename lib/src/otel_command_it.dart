// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:command_it/command_it.dart' as ci;
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_command_it_suppression.dart';

const _tracerName = 'otel_command_it';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Typed attribute keys for command_it spans.
///
/// `command_it` is Thomas Burkhart's renamed `flutter_command` — a
/// Command-pattern wrapper for UI actions (button taps, form submits,
/// refresh handlers). No upstream OTel semconv exists for it yet;
/// these `command.*` keys are package-local until a proposal lands.
enum CommandItSemantics implements OTelSemantic {
  /// `command.name` — the span name supplied at the call site (or
  /// `<anonymous>` when none was given). `command_it` keeps its
  /// own `debugName` private, so the wrapper can't read it.
  commandName('command.name'),

  /// `command.system` — always `command_it` for spans we emit.
  commandSystem('command.system'),

  /// `command.result` — `success` / `error`.
  commandResult('command.result');

  const CommandItSemantics(this.key);

  @override
  final String key;

  @override
  String toString() => key;
}

/// Traced operations on [ci.Command].
///
/// `command_it`'s state propagates via notifiers that filter "no-op"
/// updates by `==`. That means a sync command whose result equals
/// its initial value doesn't fire any listener — so we can't reliably
/// observe execution from the outside. Instead, instrument at the
/// *call site*: replace `cmd.execute(...)` with
/// `cmd.executeTraced(...)` and `cmd.executeWithFuture(...)` with
/// `cmd.executeTracedWithFuture(...)`.
///
/// Both produce a CLIENT-kind span named `command_it <name>`
/// (defaults to `<anonymous>`) carrying `command.name`,
/// `command.system=command_it`, and `command.result` =
/// `success` / `error`. Errors get `error.type` +
/// `recordException` + `Error` status, then rethrow.
extension OTelCommand<TParam, TResult> on ci.Command<TParam, TResult> {
  /// Synchronous-style executor: opens a span, calls [run] on the
  /// underlying command, closes the span when it returns or throws.
  /// (In `command_it` 9.x, `run` is the renamed `execute`.)
  void runTraced([TParam? param, String spanName = '<anonymous>']) {
    if (commandItInstrumentationSuppressed()) {
      run(param);
      return;
    }
    final span = _openSpan(spanName);
    try {
      run(param);
    } catch (e, st) {
      _endError(span, e, st);
      rethrow;
    }
    _endFromResult(span, results.value);
  }

  /// Async-style executor: opens a span, awaits [runAsync], closes
  /// the span when the future completes or throws.
  /// (In `command_it` 9.x, `runAsync` is the renamed
  /// `executeWithFuture`.)
  Future<TResult> runAsyncTraced([
    TParam? param,
    String spanName = '<anonymous>',
  ]) async {
    if (commandItInstrumentationSuppressed()) {
      return runAsync(param);
    }
    final span = _openSpan(spanName);
    try {
      final result = await runAsync(param);
      _endFromResult(span, results.value);
      return result;
    } catch (e, st) {
      _endError(span, e, st);
      rethrow;
    }
  }
}

Span _openSpan(String name) {
  return _tracer().startSpan(
    'command_it $name',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(<String, Object>{
      CommandItSemantics.commandName.key: name,
      CommandItSemantics.commandSystem.key: 'command_it',
    }),
  );
}

void _endFromResult(Span span, ci.CommandResult result) {
  if (result.hasError) {
    final err = result.error;
    span.addAttributes(
      OTel.attributes([
        OTel.attributeString(
          CommandItSemantics.commandResult.key,
          'error',
        ),
        if (err != null)
          OTel.attributeString(
            ErrorAttributes.errorType.key,
            err.runtimeType.toString(),
          ),
      ]),
    );
    if (err != null) span.recordException(err);
    span.setStatus(SpanStatusCode.Error, err?.toString() ?? 'command error');
  } else {
    span.addAttributes(
      OTel.attributes([
        OTel.attributeString(
          CommandItSemantics.commandResult.key,
          'success',
        ),
      ]),
    );
  }
  span.end();
}

void _endError(Span span, Object error, StackTrace stackTrace) {
  span.addAttributes(
    OTel.attributes([
      OTel.attributeString(
        CommandItSemantics.commandResult.key,
        'error',
      ),
      OTel.attributeString(
        ErrorAttributes.errorType.key,
        error.runtimeType.toString(),
      ),
    ]),
  );
  span.recordException(error, stackTrace: stackTrace);
  span.setStatus(SpanStatusCode.Error, error.toString());
  span.end();
}
