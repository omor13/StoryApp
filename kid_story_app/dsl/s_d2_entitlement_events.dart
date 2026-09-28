/// KidStoryApp — Schema Batch D2: `entitlements/{uid}/events/{eventId}`.
///
/// Fields are exactly docs/FIREBASE_SCHEMA.md §11.1. Two levels deep, so it is
/// representable (unlike favorites/progress, which are three).
///
/// SERVER-WRITTEN ONLY, and §11.1 is explicit that there is NO client access at
/// all — not even read. Document ID is the RevenueCat event ID, giving webhook
/// idempotency. Raw payloads are deliberately NOT stored here; only a digest.
///
/// Defined but inactive: no webhook, no Cloud Function, no Blaze.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';
import '_schema_util.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildD2,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectName: options.projectName,
      projectId: options.projectId,
      findOrCreate: options.findOrCreate,
      allowNewProject: options.allowNewProject,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error)}');
    exit(1);
  }
}

void buildD2(App app) {
  app.raw((project) {
    ensureSubcollection(
      project,
      parentName: 'entitlements',
      name: 'events',
      description:
          'SERVER-WRITTEN ONLY entitlement audit trail. NO client access at '
          'all, not even read. Document ID is the RevenueCat event ID for '
          'webhook idempotency. Raw payloads are kept in Cloud Logging, not '
          'here — only payloadDigest. INACTIVE until the webhook phase. See '
          'docs/FIREBASE_SCHEMA.md section 11.1.',
      fields: {
        'type': fsString,
        'eventAt': fsTimestamp,
        'receivedAt': fsTimestamp,
        'productId': fsString,
        'store': fsString,
        'environment': fsString,
        'resultPremiumActive': fsBool,
        'payloadDigest': fsString,
      },
    );
  });
}
