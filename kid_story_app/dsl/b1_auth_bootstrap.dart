/// KidStoryApp — Batch B1: anonymous-auth bootstrap.
///
/// Creates the two dedicated routing pages and points Firebase auth at them.
///
/// WHY TWO PAGES: FlutterFlow navigates a successfully authenticated user to
/// its configured Logged In Page automatically. Putting the anonymous sign-in
/// on HomePage would therefore fire that redirect and skip child onboarding.
/// So sign-in lives on AuthEntryPage (the logged-out entry page) and the
/// routing decision lives on AppBootstrapPage (the Logged In Page).
///
/// Flow:
///   AuthEntryPage  -- anonymous sign-in -->  AppBootstrapPage
///   AppBootstrapPage -- no children -->      HomePage (onboarding)
///   AppBootstrapPage -- has children -->     StorySelectionPage
///
/// EDITOR STEPS STILL REQUIRED after this push — see
/// docs/AUTH_BOOTSTRAP.md. The most important one: the children query on
/// AppBootstrapPage needs its Parent Document Reference set, because the DSL
/// cannot supply one and an unparented subcollection query compiles to
/// `collectionGroup('children')`, which the deployed rules deny.
library;

import 'dart:io';

import 'package:flutterflow_ai/flutterflow_ai.dart';

import '../lib/flutterflow_project.dart' as ff;
import '_cli.dart';

Future<void> main(List<String> args) async {
  final options = parseCliOptions(args);
  try {
    await flutterFlowAI(
      buildB1,
      apiKey: options.apiKey,
      baseUrl: options.baseUrl,
      projectId: options.projectId,
      dryRun: options.dryRun,
      commitMessage: options.commitMessage,
    );
  } catch (error) {
    stderr.writeln('Error: ${formatFlutterFlowAIError(error)}');
    exit(1);
  }
}

// Reused from the existing design — no new external images.
const _bg = 'projects/kid-story-app-vel697/assets/ufebfdsuaoan/Home_Screen_(1).png';
const _mark = 'projects/kid-story-app-vel697/assets/dv1xq6rc3xf7/book_large_no_background.png';

const _ink = 0xFF352071;
const _cardBg = 0xFFFFFFFF;
const _errorInk = 0xFFB3261E;

void buildB1(App app) {
  // ---- Phase 6: selected-child state -------------------------------------
  // Only the Firestore document ID, never the child document itself. It is a
  // convenience for restoring the last-used child, never an authorization
  // input — Firestore rules remain authoritative.
  app.state(
    'selectedChildId',
    string,
    persisted: true,
    description:
        'Firestore document ID of the active child under '
        'users/{uid}/children. Empty when no child is selected. Never used '
        'for authorization; always re-verified against the current user.',
  );

  // The visual avatar choice behind the ولد / بنت cards. Mirrors the selected
  // child avatarId and nothing else. NO gender is stored anywhere: see
  // docs/FIREBASE_SCHEMA.md section 4.1. Per child, avatarId on the child
  // document is authoritative; this field is only the active child copy.
  app.state(
    'selectedAvatarId',
    string,
    persisted: true,
    description:
        'Canonical avatar id (avatar_01..avatar_12) of the active child, '
        'mirroring children.avatarId. Drives the onboarding card highlight. '
        'Never a gender value and never written to Firestore as one.',
  );

  // ---- Phase 3: AuthEntryPage --------------------------------------------
  app.ensurePage(
    'AuthEntryPage',
    route: '/auth-entry',
    description:
        'Logged-out entry page. Signs the parent in anonymously, then lets '
        'FlutterFlow route to the Logged In Page (AppBootstrapPage). Must '
        'NOT require authentication.',
    // 'loading' while an attempt is in flight, 'failed' after a failure.
    // Guarding the retry on this value is what prevents overlapping sign-ins.
    state: {'phase': string},
    onLoad: [
      If(
        Not(Equals(AuthUser(AuthUserField.userId), '')),
        // Already signed in (returning install) — skip sign-in entirely.
        then: [
          Navigate(
            'AppBootstrapPage',
            replaceRoute: true,
            allowBack: false,
          ),
        ],
        orElse: [
          SetState('phase', 'loading'),
          LoginAnonymously(),
          // NOTE: FlutterFlow emits `if (user == null) { return; }` straight
          // after a login action, so nothing below runs when sign-in FAILS.
          // A failed attempt is therefore invisible to this chain, which is
          // why the retry control below is unconditional rather than gated on
          // a failure flag. This check still covers the odd case of a
          // returned user with an empty uid.
          If(
            Equals(AuthUser(AuthUserField.userId), ''),
            then: [SetState('phase', 'failed')],
          ),
        ],
      ),
    ],
    body: Scaffold(
      body: Stack(
        children: [
          Image(_bg, isNetwork: false, width: double.infinity,
              height: double.infinity, fit: ImageFit.cover, name: 'authEntryBackground'),
          Column(
            mainAxis: MainAxis.center,
            crossAxis: CrossAxis.center,
            spacing: 20,
            children: [
              Image(_mark, isNetwork: false, width: 120, height: 104,
                  name: 'authEntryMark'),
              Text(
                'جارٍ تجهيز عالم الحكايات...',
                style: Styles.titleMedium,
                color: Colors.hex(_ink),
                textAlign: TextAlign.center,
                name: 'authEntryLoadingText',
                visible: Not(Equals(State('phase'), 'failed')),
              ),
              ProgressBar.circular(
                size: 44,
                name: 'authEntrySpinner',
                visible: Not(Equals(State('phase'), 'failed')),
              ),
              Container(
                color: Colors.hex(_cardBg),
                borderRadius: 16,
                padding: EdgeInsets.all(20),
                width: 320,
                name: 'authEntryErrorCard',
                child: Column(
                  spacing: 16,
                  crossAxis: CrossAxis.center,
                  children: [
                    Text(
                      'تعذّر الاتصال. تحقّق من الإنترنت وحاول مرة أخرى.',
                      style: Styles.bodyMedium,
                      color: Colors.hex(_errorInk),
                      textAlign: TextAlign.center,
                      name: 'authEntryErrorText',
                      visible: Equals(State('phase'), 'failed'),
                    ),
                    Button(
                      'إعادة المحاولة',
                      name: 'authEntryRetryButton',
                      color: Colors.hex(_ink),
                      textColor: Colors.hex(0xFFFFFFFF),
                      borderRadius: 12,
                      height: 48,
                      width: 200,
                      // Guarded on "there is still no uid" rather than on a
                      // page-state flag. A pessimistic flag would deadlock:
                      // FlutterFlow returns early from the chain when sign-in
                      // fails, so nothing could ever reset it and the retry
                      // would be permanently disabled in exactly the case it
                      // is needed. This guard self-clears — once a uid
                      // exists, no further sign-in can be started.
                      onTap: [
                        If(
                          Equals(AuthUser(AuthUserField.userId), ''),
                          then: [
                            SetState('phase', 'loading'),
                            LoginAnonymously(),
                            If(
                              Equals(AuthUser(AuthUserField.userId), ''),
                              then: [SetState('phase', 'failed')],
                            ),
                          ],
                          // Already signed in: go where the router would.
                          orElse: [
                            Navigate('AppBootstrapPage',
                                replaceRoute: true, allowBack: false),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ---- Phase 5: AppBootstrapPage -----------------------------------------
  app.ensurePage(
    'AppBootstrapPage',
    route: '/app-bootstrap',
    description:
        'Logged In Page. Reads the authenticated parent children and routes '
        'to HomePage (onboarding) or StorySelectionPage. Requires auth — set '
        'that in the editor. The children query needs its Parent Document '
        'Reference set to Authenticated User > Document Reference.',
    state: {'phase': string},
    onLoad: [
      // limit 5 == appConfig.maxChildrenPerParent (D-07 default).
      // orderBy createdAt is the only documented ordering field on the
      // children schema (FIREBASE_SCHEMA.md section 4).
      //
      // EDITOR STEP: this action has no Parent Document Reference, because
      // FirestoreQuery in the DSL takes none. Until it is set by hand it
      // compiles to collectionGroup('children'), which the deployed rules
      // correctly deny for non-admins.
      FirestoreQuery(
        ff.Collections.children,
        orderBy: FirestoreOrderBy('createdAt'),
        limit: 5,
        outputAs: 'bootstrapChildren',
      ),
      If(
        Equals(Count(ActionOutput('bootstrapChildren')), 0),
        then: [
          // No child yet: drop any stale selection and onboard.
          ClearAppState('selectedChildId'),
          ClearAppState('selectedAvatarId'),
          Navigate('HomePage', replaceRoute: true, allowBack: false),
        ],
        orElse: [
          Navigate(
            'StorySelectionPage',
            replaceRoute: true,
            allowBack: false,
          ),
        ],
      ),
    ],
    body: Scaffold(
      body: Stack(
        children: [
          Image(_bg, isNetwork: false, width: double.infinity,
              height: double.infinity, fit: ImageFit.cover, name: 'bootstrapBackground'),
          Column(
            mainAxis: MainAxis.center,
            crossAxis: CrossAxis.center,
            spacing: 20,
            children: [
              Image(_mark, isNetwork: false, width: 120, height: 104,
                  name: 'bootstrapMark'),
              Text(
                'جارٍ تحميل ملف الطفل...',
                style: Styles.titleMedium,
                color: Colors.hex(_ink),
                textAlign: TextAlign.center,
                name: 'bootstrapLoadingText',
              ),
              ProgressBar.circular(
                size: 44,
                name: 'bootstrapSpinner',
              ),
              Text(
                'حدث خطأ أثناء تحميل الملف.',
                style: Styles.bodyMedium,
                color: Colors.hex(_errorInk),
                textAlign: TextAlign.center,
                name: 'bootstrapErrorText',
                visible: Equals(State('phase'), 'failed'),
              ),
              // Deliberately always visible. A Firestore query that throws
              // (permission denied, offline) aborts the page-load chain, and
              // the DSL has no catch, so a conditional retry could never be
              // reached in exactly the case it is needed.
              Button(
                'إعادة المحاولة',
                name: 'bootstrapRetryButton',
                color: Colors.hex(_ink),
                textColor: Colors.hex(0xFFFFFFFF),
                borderRadius: 12,
                height: 48,
                width: 200,
                onTap: [
                  FirestoreQuery(
                    ff.Collections.children,
                    orderBy: FirestoreOrderBy('createdAt'),
                    limit: 5,
                    outputAs: 'retryChildren',
                  ),
                  If(
                    Equals(Count(ActionOutput('retryChildren')), 0),
                    then: [
                      ClearAppState('selectedChildId'),
                      ClearAppState('selectedAvatarId'),
                      Navigate('HomePage', replaceRoute: true, allowBack: false),
                    ],
                    orElse: [
                      Navigate('StorySelectionPage',
                          replaceRoute: true, allowBack: false),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ---- Phase 7: authentication routing -----------------------------------
  // signInPage is the logged-out Entry Page; homePage is the Logged In Page.
  // Only the anonymous provider — no email, phone, Google or Apple.
  //
  // autoCreateUserDocument writes users/{uid} through
  // createUsersRecordData(), which emits only fields that exist in the
  // schema and drops nulls. For an anonymous user that is uid +
  // created_time: no privileged key, so the deployed users rule accepts it.
  app.ensureFirebaseAuth(
    providers: [FirebaseAuthProvider.anonymous],
    homePage: 'AppBootstrapPage',
    signInPage: 'AuthEntryPage',
    autoCreateUserDocument: true,
    userCollectionName: 'users',
  );
}
