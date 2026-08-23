import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('architecture boundaries', () {
    test('public barrels export only the supported core surface', () {
      expect(_exportsOf('lib/adaptive_actions.dart'), ["export 'core.dart';"]);
      expect(_exportsOf('lib/core.dart'), _supportedCoreExports);
    });

    test('Cupertino entrypoint exports only core and Cupertino APIs', () {
      expect(_exportsOf('lib/cupertino.dart'), [
        "export 'core.dart';",
        "export 'src/cupertino/cupertino_adaptive_actions.dart';",
      ]);
    });

    test('Cupertino library does not import or export Material APIs', () {
      final forbiddenDirectives = <String>[];
      final files = <File>[
        File('lib/cupertino.dart'),
        ...Directory('lib/src/cupertino')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart')),
      ];

      for (final file in files) {
        for (final line in file.readAsLinesSync()) {
          final directive = line.trim();
          if ((directive.startsWith('import ') ||
                  directive.startsWith('export ')) &&
              _forbiddenCupertinoDependencies.any(directive.contains)) {
            forbiddenDirectives.add('${file.path}: $directive');
          }
        }
      }

      expect(forbiddenDirectives, isEmpty);
    });

    test('core source does not import Flutter or platform UI libraries', () {
      final forbiddenImports = <String>[];
      final coreFiles = Directory('lib/src/core')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in coreFiles) {
        for (final line in file.readAsLinesSync()) {
          final import = line.trim();
          if (_forbiddenImportPrefixes.any(import.startsWith)) {
            forbiddenImports.add('${file.path}: $import');
          }
        }
      }

      expect(forbiddenImports, isEmpty);
    });

    test('core source contains no superseded public API terminology', () {
      final matches = <String>[];
      final coreFiles = Directory('lib/src/core')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in coreFiles) {
        final source = file.readAsStringSync();
        for (final term in _supersededPublicTerms) {
          if (source.contains(term)) {
            matches.add('${file.path}: $term');
          }
        }
      }

      expect(matches, isEmpty);
    });

    test('layout placement input is normalized only at request boundary', () {
      final normalizationFiles = <String>[];
      var normalizationCount = 0;
      final coreFiles = Directory('lib/src/core')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.dart') &&
                !file.path.endsWith(
                  'action_placement_input_normalization.dart',
                ),
          );

      for (final file in coreFiles) {
        final source = file.readAsStringSync();
        final count = '.normalizeForPlacement('.allMatches(source).length;
        if (count > 0) {
          normalizationFiles.add(
            file.path.split(Platform.pathSeparator).join('/'),
          );
          normalizationCount += count;
        }
      }

      expect(normalizationCount, 1);
      expect(normalizationFiles, ['lib/src/core/action_layout.dart']);
    });
  });
}

List<String> _exportsOf(String path) => File(path)
    .readAsLinesSync()
    .map((line) => line.trim())
    .where((line) => line.startsWith('export '))
    .toList(growable: false);

const _supportedCoreExports = [
  "export 'src/core/action_collection.dart';",
  "export 'src/core/action_collection_entry.dart';",
  "export 'src/core/action_id.dart';",
  "export 'src/core/action_layout.dart';",
  "export 'src/core/action_layout_constraints.dart';",
  "export 'src/core/action_layout_resolver.dart';",
  "export 'src/core/action_metadata.dart';",
  "export 'src/core/action_placement_constraints.dart';",
  "export 'src/core/action_placement_delegate.dart';",
  "export 'src/core/action_placement_policy.dart';",
  "export 'src/core/adaptive_action.dart';",
  "export 'src/core/renderer_capabilities.dart';",
];

const _forbiddenImportPrefixes = [
  "import 'dart:ui'",
  "import 'package:flutter/",
  "import 'package:adaptive_actions/adaptive_actions_material.dart'",
  "import 'package:adaptive_actions/adaptive_actions_cupertino.dart'",
];

const _forbiddenCupertinoDependencies = [
  'package:flutter/material.dart',
  '/material.dart',
  '/src/material/',
  '../material/',
];

const _supersededPublicTerms = [
  'ActionPlacementGroup',
  'ActionPlacementResolver',
  'ActionResolutionRequest',
  'ActionCostProfile',
  'CollapsePriority',
  'CollapsePreference',
  'placementGroups',
  'placementGroup',
  'hardPlacement',
  'collapsePriority',
  'collapsePreference',
  'allowHiding',
  'costProfiles',
  'costProfileFor',
  'placementResolver',
  'action_placement_resolver.dart',
  'ActionLayoutInputValidator',
  'ActionLayoutInputPreparer',
  'normalizeActionPlacementInput',
  'actionCollection',
  'layoutConstraints',
  'rendererCapabilities',
  'layoutProfiles',
  'layoutProfileFor',
  'layoutOptionId',
];
