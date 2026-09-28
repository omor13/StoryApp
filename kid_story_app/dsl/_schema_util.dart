/// Subcollection authoring helper.
///
/// The typed DSL's `app.collection(name, fields:)` can only create TOP-LEVEL
/// collections — it has no parent parameter. The SDK does ship an
/// `addCollection(..., parentCollection:)` helper that sets
/// `FFCollection.parentCollectionIdentifier`, but `src/helpers/collection_helpers.dart`
/// is not exported from the public barrel, so it cannot be called directly.
///
/// This helper reproduces exactly that behaviour inside `app.raw`, using only
/// publicly exported schema types. It writes the same single proto field the
/// official helper writes, so the documented
/// `stories/{storyId}/pages/{pageId}` nesting is preserved rather than
/// flattened.
///
/// Both functions are idempotent: re-running a batch will not duplicate a
/// collection or a field.
library;

import 'dart:math';

import 'package:flutterflow_ai/flutterflow_ai.dart';

const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _rng = Random();

String _key() =>
    List.generate(16, (_) => _alphabet[_rng.nextInt(_alphabet.length)]).join();

/// Looks up a collection by name, returning null when absent.
FFCollection? findCollectionByName(FFProject project, String name) {
  for (final c in project.ensureBackend().collections.values) {
    if (c.identifier.name == name) return c;
  }
  return null;
}

/// Creates a subcollection under [parentName], or tops up a missing field on it
/// if it already exists. Returns the collection.
///
/// Throws if the parent does not exist — create parents in an earlier batch.
FFCollection ensureSubcollection(
  FFProject project, {
  required String parentName,
  required String name,
  required String description,
  required Map<String, FFDataTypeV2> fields,
}) {
  final parent = findCollectionByName(project, parentName);
  if (parent == null) {
    throw StateError(
      'Parent collection "$parentName" not found — create it in an earlier '
      'batch before adding the "$name" subcollection.',
    );
  }

  final collections = project.ensureBackend().collections;
  var existing = findCollectionByName(project, name);

  if (existing == null) {
    final key = _key();
    final created = FFCollection(
      identifier: FFIdentifier(name: name, key: key),
      description: description,
    );
    created.parentCollectionIdentifier = parent.identifier;
    collections[key] = created;
    existing = created;
  } else {
    // Re-point the parent only if it drifted; never silently reparent to a
    // different collection than the one asked for.
    if (existing.parentCollectionIdentifier.name != parentName) {
      throw StateError(
        'Collection "$name" already exists with parent '
        '"${existing.parentCollectionIdentifier.name}", not "$parentName". '
        'Refusing to reparent silently.',
      );
    }
  }

  for (final entry in fields.entries) {
    final present = existing.fields.values.any(
      (f) => f.identifier.name == entry.key,
    );
    if (present) continue;
    existing.fields[entry.key] = FFParameter(
      identifier: FFIdentifier(name: entry.key, key: entry.key),
      dataType: entry.value,
    );
  }
  return existing;
}

// --- FFDataTypeV2 builders (src/helpers/data_type_helpers.dart is not
// --- exported either, so the scalar types are constructed directly).
FFDataTypeV2 get fsString => FFDataTypeV2(scalarType: FFBaseDataType.String);
FFDataTypeV2 get fsInt => FFDataTypeV2(scalarType: FFBaseDataType.Integer);
FFDataTypeV2 get fsDouble => FFDataTypeV2(scalarType: FFBaseDataType.Double);
FFDataTypeV2 get fsBool => FFDataTypeV2(scalarType: FFBaseDataType.Boolean);
FFDataTypeV2 get fsTimestamp =>
    FFDataTypeV2(scalarType: FFBaseDataType.DateTime);
FFDataTypeV2 get fsJson => FFDataTypeV2(scalarType: FFBaseDataType.JSON);

/// `array<string>` in the schema docs. A list is expressed by nesting the
/// element type under `listType`, matching the SDK's own `listOf(...)`.
FFDataTypeV2 get fsStringList => FFDataTypeV2(listType: fsString);
