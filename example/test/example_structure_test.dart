import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const platformRunnerMarkers = {
    'android': 'android/app/src/main/AndroidManifest.xml',
    'ios': 'ios/Runner/Info.plist',
    'linux': 'linux/runner/main.cc',
    'macos': 'macos/Runner/MainFlutterWindow.swift',
    'web': 'web/index.html',
    'windows': 'windows/runner/main.cpp',
  };

  test('keeps renderer integrations and settings in their intended files', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final cupertinoSource = File('lib/cupertino_demo.dart').readAsStringSync();
    final settingsSource = File(
      'lib/demo_settings_widgets.dart',
    ).readAsStringSync();

    expect(mainSource, contains('package:adaptive_actions/material.dart'));
    expect(mainSource, contains('MaterialAdaptiveActions<DemoCommand>'));
    expect(
      mainSource,
      isNot(contains('package:adaptive_actions/cupertino.dart')),
    );
    expect(mainSource, isNot(contains('package:flutter/cupertino.dart')));
    expect(mainSource, isNot(contains('CupertinoAdaptiveActions')));

    expect(
      cupertinoSource,
      contains('package:adaptive_actions/cupertino.dart'),
    );
    expect(cupertinoSource, contains('CupertinoAdaptiveActions<T>'));
    expect(
      settingsSource,
      contains('final class DemoActionSettings extends StatelessWidget'),
    );
    expect(
      settingsSource,
      contains('final class DemoAnimationSettings extends StatelessWidget'),
    );
    expect(
      settingsSource,
      contains('final class DemoPresentationSettings extends StatelessWidget'),
    );
  });

  test('uses public package APIs and keeps all six platform runners', () {
    final dartSources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final source in dartSources) {
      expect(source.readAsStringSync(), isNot(contains('/src/')));
    }
    for (final entry in platformRunnerMarkers.entries) {
      expect(
        File(entry.value).existsSync(),
        isTrue,
        reason: '${entry.key} runner is missing ${entry.value}',
      );
    }
  });
}
