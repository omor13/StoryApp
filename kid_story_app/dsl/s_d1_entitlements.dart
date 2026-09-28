/// KidStoryApp — Schema Batch D1: `entitlements/{uid}`.
///
/// Fields are exactly docs/FIREBASE_SCHEMA.md §11.
///
/// SERVER-MANAGED AND INACTIVE. This batch defines the schema only:
/// - No synchronisation is implemented.
/// - No Cloud Function is written or deployed.
/// - Blaze billing is not enabled.
/// - No client write path is created anywhere in the app.
///
/// The collection stays dormant until the RevenueCat webhook phase. Until the
/// deny-all client-write rule in docs/FIREBASE_SECURITY_PLAN.md is deployed,
/// nothing may read it for access decisions either — premium access is still
/// locked, by design.
///
/// `manualGrant` is documented as `map` and is authored as JSON, consistent
/// with users.settings / users.consent / stories.credits.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildD1,
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

void buildD1(App app) {
  app.collection(
    'entitlements',
    description:
        'SERVER-WRITTEN ONLY — subscription mirror of the RevenueCat '
        'premium_library entitlement. Document ID is the Firebase Auth UID. '
        'INACTIVE: no sync, no Cloud Function, no client write path exists '
        'yet. Clients may eventually READ their own document; they may NEVER '
        'write it. See docs/FIREBASE_SCHEMA.md section 11.',
    fields: {
      'premiumActive': bool_,
      'accessExpiresAt': dateTime,
      'entitlementId': string,
      'productId': string,
      'store': string,
      'periodType': string,
      'purchasedAt': dateTime,
      'expiresAt': dateTime,
      'willRenew': bool_,
      'unsubscribeDetectedAt': dateTime,
      'billingIssueDetectedAt': dateTime,
      'gracePeriodExpiresAt': dateTime,
      'isSandbox': bool_,
      'revenuecatAppUserId': string,
      'originalAppUserId': string,
      'lastEventType': string,
      'lastEventId': string,
      'lastEventAt': dateTime,
      'lastSyncedAt': dateTime,
      'lastSyncSource': string,
      'grantedAt': dateTime,
      'revokedAt': dateTime,
      'manualGrant': json,
      'updatedAt': dateTime,
    },
  );
}
