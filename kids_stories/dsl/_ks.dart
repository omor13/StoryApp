/// Typed component handles for the Kids Stories components.
///
/// Why this file exists: FlutterFlow stores a component's callback parameter
/// as an editor "Action" type, and the generated typed SDK has no DslType for
/// it, so `lib/flutterflow_project/components/*.dart` degrades those params to
/// `ffai.json` (see FlutterFlow/flutterflow-issues#7323). Passing a list of
/// actions to such a param then fails with "Expected a DSL expression or
/// scalar literal".
///
/// These wrappers re-declare the callback params as `action` on top of the
/// generated handles, so pages can pass real action chains. Everything else —
/// name, key, widget tree — comes straight from the generated SDK.
///
/// The handles are typed `dynamic` on purpose: `ProjectComponentHandle`
/// exposes its `call(...)` through `noSuchMethod`, which only dispatches on a
/// dynamic receiver.
library;

import 'package:flutterflow_ai/flutterflow_ai.dart';
import 'package:kids_stories/flutterflow_project.dart' as ff;

dynamic _withActions(
  ProjectComponentHandle<dynamic, dynamic> handle,
  List<String> callbackParams,
) => ProjectComponentHandle<dynamic, dynamic>(
  name: handle.name,
  key: handle.key,
  params: handle.params,
  state: handle.state,
  widgets: handle.widgets,
  description: handle.description,
  paramTypes: <String, DslType>{
    ...handle.paramTypes,
    for (final param in callbackParams) param: action,
  },
);

final dynamic ksPrimaryButton = _withActions(ff.Components.ksprimaryButton, [
  'onPressed',
]);
final dynamic ksSecondaryButton = _withActions(ff.Components.kssecondaryButton, [
  'onPressed',
]);
final dynamic ksCircularIconButton = _withActions(ff.Components.kscircularIconButton, [
  'onPressed',
]);
final dynamic ksStoryCard = _withActions(ff.Components.ksstoryCard, ['onTap']);
final dynamic ksPageNavigation = _withActions(ff.Components.kspageNavigation, [
  'onPrevious',
  'onNext',
  'onFinish',
]);
final dynamic ksSubscriptionPlanCard = _withActions(
  ff.Components.kssubscriptionPlanCard,
  ['onSelect'],
);
final dynamic ksLockedStoryOverlay = _withActions(ff.Components.kslockedStoryOverlay, [
  'onParentTap',
  'onClose',
]);
final dynamic ksEmptyState = _withActions(ff.Components.ksemptyState, ['onAction']);
final dynamic ksErrorState = _withActions(ff.Components.kserrorState, ['onRetry']);

// Components with no callback params are used straight from the generated SDK:
// ff.Components.ksageGroupSelector, ksavatarSelector, ksreadingModeSelector,
// ksaudioControls, ksstoryTextCard, ksloadingState.
