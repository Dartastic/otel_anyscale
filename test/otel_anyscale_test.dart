// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_anyscale/otel_anyscale.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_anyscale-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('jobs.create records compute + GPU + status', () async {
    await tracedAnyscale<String>(
      operation: 'jobs.create',
      invoke: () async => const AnyscaleCallResult(
        value: 'ok',
        result: AnyscaleResult(
          surface: 'jobs',
          jobId: 'j_1',
          jobStatus: 'STARTING',
          workerNodeKind: 'g5.2xlarge',
          headNodeKind: 'm5.xlarge',
          workerCount: 4,
          gpuType: 'A10G',
          gpuCount: 4,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('anyscale jobs.create')!);
    expect(a['anyscale.gpu.type'], 'A10G');
    expect(a['anyscale.worker.count'], 4);
  });

  test('FAILED job sets span error', () async {
    await tracedAnyscale<String>(
      operation: 'jobs.get',
      invoke: () async => const AnyscaleCallResult(
        value: 'ok',
        result: AnyscaleResult(
          jobId: 'j_1',
          jobStatus: 'FAILED',
          jobAttemptCount: 3,
        ),
      ),
    );
    expect(
      spans.findSpanByName('anyscale jobs.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('UNHEALTHY service sets span error', () async {
    await tracedAnyscale<String>(
      operation: 'services.get',
      invoke: () async => const AnyscaleCallResult(
        value: 'ok',
        result: AnyscaleResult(
          surface: 'services',
          serviceId: 's_1',
          serviceVersion: 'v3',
          serviceStatus: 'UNHEALTHY',
        ),
      ),
    );
    expect(
      spans.findSpanByName('anyscale services.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('endpoint inference records tokens', () async {
    await tracedAnyscale<String>(
      operation: 'endpoints.chatCompletions',
      invoke: () async => const AnyscaleCallResult(
        value: 'ok',
        result: AnyscaleResult(
          surface: 'endpoints',
          endpointModel: 'meta-llama/Llama-3-70b-chat-hf',
          totalTokens: 1500,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('anyscale endpoints.chatCompletions')!,
    );
    expect(a['anyscale.endpoint.model'], 'meta-llama/Llama-3-70b-chat-hf');
  });

  test('suppression skips spans', () async {
    await runWithoutAnyscaleInstrumentationAsync(() async {
      await tracedAnyscale<String>(
        operation: 'clusters.list',
        invoke: () async => const AnyscaleCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('anyscale '), isEmpty);
  });
}
