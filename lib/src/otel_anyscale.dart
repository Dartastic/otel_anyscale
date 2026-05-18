// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_anyscale_suppression.dart';

const _tracerName = 'dartastic_otel_libs_anyscale';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class AnyscaleResult {
  const AnyscaleResult({
    this.surface,
    this.cloudId,
    this.projectId,
    this.workspaceId,
    this.computeConfigId,
    this.workerNodeKind,
    this.headNodeKind,
    this.workerCount,
    this.gpuType,
    this.gpuCount,
    this.jobId,
    this.jobStatus,
    this.jobAttemptCount,
    this.serviceId,
    this.serviceVersion,
    this.serviceStatus,
    this.endpointModel,
    this.streamed,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.durationSec,
    this.instanceHoursMillis,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// `clouds`, `projects`, `workspaces`, `jobs`, `services`, `endpoints`,
  /// `compute_configs`, `cluster_envs`, `experimental`.
  final String? surface;

  final String? cloudId;
  final String? projectId;
  final String? workspaceId;
  final String? computeConfigId;

  /// Worker/head AWS or GCP instance type.
  final String? workerNodeKind;
  final String? headNodeKind;

  final int? workerCount;

  /// `A10G`, `A100-40G`, `A100-80G`, `H100`, `L4`, `T4`.
  final String? gpuType;
  final int? gpuCount;

  // ── Jobs ──────────────────────────────────────────────────────
  final String? jobId;

  /// `PENDING`, `AWAITING_CLUSTER_START`, `STARTING`, `RUNNING`,
  /// `SUCCEEDED`, `FAILED`, `STOPPED`, `OUT_OF_RETRIES`.
  final String? jobStatus;
  final int? jobAttemptCount;

  // ── Services ──────────────────────────────────────────────────
  final String? serviceId;
  final String? serviceVersion;

  /// `STARTING`, `RUNNING`, `UPDATING`, `ROLLING_OUT`, `ROLLING_BACK`,
  /// `TERMINATED`, `UNHEALTHY`, `SYSTEM_FAILURE`.
  final String? serviceStatus;

  // ── Endpoints (OpenAI-compat inference) ───────────────────────
  final String? endpointModel;
  final bool? streamed;

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  final int? durationSec;

  /// Compute-hours consumed in millihours (Anyscale billing unit).
  final int? instanceHoursMillis;

  final String? errorCode;
  final String? errorMessage;
  final int? statusCode;
}

class AnyscaleCallResult<T> {
  const AnyscaleCallResult({required this.value, this.result});
  final T value;
  final AnyscaleResult? result;
}

/// Wraps an Anyscale API call in a CLIENT span. [operation] is one of
/// `jobs.create`, `jobs.get`, `jobs.list`, `jobs.terminate`,
/// `jobs.archive`, `jobs.logs`, `services.create`, `services.get`,
/// `services.list`, `services.rollout`, `services.rollback`,
/// `services.terminate`, `services.archive`, `clusters.create`,
/// `clusters.terminate`, `clusters.list`, `computeConfigs.create`,
/// `computeConfigs.delete`, `clusterEnvs.create`, `clusterEnvs.list`,
/// `endpoints.chatCompletions`, `endpoints.completions`,
/// `endpoints.embeddings`, `workspaces.create`, `workspaces.start`,
/// `workspaces.terminate`, `workspaces.list`.
Future<T> tracedAnyscale<T>({
  required String operation,
  required Future<AnyscaleCallResult<T>> Function() invoke,
}) async {
  if (anyscaleInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'anyscale',
    'rpc.method': operation,
    'anyscale.operation': operation,
  };

  final span = _tracer().startSpan(
    'anyscale $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.surface != null) {
        extras.add(OTel.attributeString('anyscale.surface', res.surface!));
      }
      if (res.cloudId != null) {
        extras.add(OTel.attributeString('anyscale.cloud.id', res.cloudId!));
      }
      if (res.projectId != null) {
        extras.add(OTel.attributeString(
          'anyscale.project.id',
          res.projectId!,
        ));
      }
      if (res.workspaceId != null) {
        extras.add(OTel.attributeString(
          'anyscale.workspace.id',
          res.workspaceId!,
        ));
      }
      if (res.computeConfigId != null) {
        extras.add(OTel.attributeString(
          'anyscale.compute_config.id',
          res.computeConfigId!,
        ));
      }
      if (res.workerNodeKind != null) {
        extras.add(OTel.attributeString(
          'anyscale.worker.node_kind',
          res.workerNodeKind!,
        ));
      }
      if (res.headNodeKind != null) {
        extras.add(OTel.attributeString(
          'anyscale.head.node_kind',
          res.headNodeKind!,
        ));
      }
      if (res.workerCount != null) {
        extras.add(OTel.attributeInt(
          'anyscale.worker.count',
          res.workerCount!,
        ));
      }
      if (res.gpuType != null) {
        extras.add(OTel.attributeString('anyscale.gpu.type', res.gpuType!));
      }
      if (res.gpuCount != null) {
        extras.add(OTel.attributeInt('anyscale.gpu.count', res.gpuCount!));
      }
      if (res.jobId != null) {
        extras.add(OTel.attributeString('anyscale.job.id', res.jobId!));
      }
      if (res.jobStatus != null) {
        extras.add(OTel.attributeString(
          'anyscale.job.status',
          res.jobStatus!,
        ));
        if (res.jobStatus == 'FAILED' || res.jobStatus == 'OUT_OF_RETRIES') {
          span.setStatus(
            SpanStatusCode.Error,
            'Anyscale job ${res.jobStatus}',
          );
        }
      }
      if (res.jobAttemptCount != null) {
        extras.add(OTel.attributeInt(
          'anyscale.job.attempt_count',
          res.jobAttemptCount!,
        ));
      }
      if (res.serviceId != null) {
        extras.add(OTel.attributeString(
          'anyscale.service.id',
          res.serviceId!,
        ));
      }
      if (res.serviceVersion != null) {
        extras.add(OTel.attributeString(
          'anyscale.service.version',
          res.serviceVersion!,
        ));
      }
      if (res.serviceStatus != null) {
        extras.add(OTel.attributeString(
          'anyscale.service.status',
          res.serviceStatus!,
        ));
        if (res.serviceStatus == 'UNHEALTHY' ||
            res.serviceStatus == 'SYSTEM_FAILURE') {
          span.setStatus(
            SpanStatusCode.Error,
            'Anyscale service ${res.serviceStatus}',
          );
        }
      }
      if (res.endpointModel != null) {
        extras.add(OTel.attributeString(
          'anyscale.endpoint.model',
          res.endpointModel!,
        ));
      }
      if (res.streamed != null) {
        extras.add(OTel.attributeBool('anyscale.streamed', res.streamed!));
      }
      if (res.promptTokens != null) {
        extras.add(OTel.attributeInt(
          'anyscale.usage.prompt_tokens',
          res.promptTokens!,
        ));
      }
      if (res.completionTokens != null) {
        extras.add(OTel.attributeInt(
          'anyscale.usage.completion_tokens',
          res.completionTokens!,
        ));
      }
      if (res.totalTokens != null) {
        extras.add(OTel.attributeInt(
          'anyscale.usage.total_tokens',
          res.totalTokens!,
        ));
      }
      if (res.durationSec != null) {
        extras.add(OTel.attributeInt(
          'anyscale.duration_sec',
          res.durationSec!,
        ));
      }
      if (res.instanceHoursMillis != null) {
        extras.add(OTel.attributeInt(
          'anyscale.instance_hours_millis',
          res.instanceHoursMillis!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'anyscale.error.code',
          res.errorCode!,
        ));
        span.setStatus(SpanStatusCode.Error, 'Anyscale ${res.errorCode}');
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'anyscale.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
              SpanStatusCode.Error, 'Anyscale HTTP ${res.statusCode}');
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
