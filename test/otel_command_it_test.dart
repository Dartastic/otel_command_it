// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:command_it/command_it.dart';
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otel_command_it/otel_command_it.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_command_it-test',
    );
    spans = harness.spans;
  });

  setUp(() {
    harness.clear();
  });

  test('sync runTraced emits span with command.result=success', () {
    final cmd = Command.createSyncNoParamNoResult(() {});
    cmd.runTraced(null, 'do.thing');

    final span = spans.findSpanByName('command_it do.thing');
    expect(span, isNotNull);
    final attrs = {for (final a in span!.attributes.toList()) a.key: a.value};
    expect(attrs['command.name'], 'do.thing');
    expect(attrs['command.system'], 'command_it');
    expect(attrs['command.result'], 'success');
    expect(span.status, isNot(SpanStatusCode.Error));
  });

  test('async runAsyncTraced spans the awaited future', () async {
    final cmd = Command.createAsyncNoParamNoResult(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await cmd.runAsyncTraced(null, 'do.async.thing');

    final span = spans.findSpanByName('command_it do.async.thing');
    expect(span, isNotNull);
    final attrs = {for (final a in span!.attributes.toList()) a.key: a.value};
    expect(attrs['command.result'], 'success');
  });

  test('async throw → span.status=Error + error.type attr', () async {
    // `command_it` v9+ requires either a local error handler or a
    // `Command.globalExceptionHandler` for the future returned by
    // `runAsync` to complete on error — otherwise it rethrows
    // synchronously and the future hangs forever. Install a no-op
    // global handler so the test exercises the failure path.
    Command.globalExceptionHandler = (cmd, err) {};
    addTearDown(() {
      Command.globalExceptionHandler = null;
    });

    final cmd = Command.createAsyncNoParamNoResult(() async {
      throw StateError('boom');
    });
    try {
      await cmd.runAsyncTraced(null, 'do.async.boom');
    } catch (_) {
      // Either rethrown or swallowed by catchAlways; we don't care.
    }
    final span = spans.findSpanByName('command_it do.async.boom');
    expect(span, isNotNull);
    expect(span!.status, SpanStatusCode.Error);
    final attrs = {for (final a in span.attributes.toList()) a.key: a.value};
    expect(attrs['command.result'], 'error');
    expect(attrs['error.type'], 'StateError');
  });

  test('default span name is <anonymous>', () {
    final cmd = Command.createSyncNoParamNoResult(() {});
    cmd.runTraced();
    expect(
      spans.findSpanByName('command_it <anonymous>'),
      isNotNull,
    );
  });

  test('zone-scoped suppression skips spans', () async {
    final cmd = Command.createSyncNoParamNoResult(() {});
    await runWithoutCommandItInstrumentationAsync(() async {
      cmd.runTraced(null, 'do.quiet');
    });
    expect(spans.findSpansStartingWith('command_it'), isEmpty);
  });

  test('sync command with TParam runs and emits a span', () {
    final received = <int>[];
    final cmd = Command.createSyncNoResult<int>(received.add);
    cmd.runTraced(42, 'add.int');
    expect(received, [42]);
    expect(
      spans.findSpanByName('command_it add.int'),
      isNotNull,
    );
  });
}
