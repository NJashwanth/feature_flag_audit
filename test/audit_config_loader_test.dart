import 'dart:io';

import 'package:feature_flag_audit/feature_flag_audit.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AuditConfigLoader', () {
    late Directory tempDir;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('feature_flag_audit_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('uses defaults when config file is missing', () async {
      final result = await AuditConfigLoader.load(projectRoot: tempDir.path);

      expect(result.loadedFromFile, isFalse);
      expect(result.config.scan.include, ['lib']);
      expect(result.config.detection.usageMethods,
          ['getBool', 'getString', 'getInt', 'getDouble']);
      expect(result.config.detection.wrapperMethods, [
        'boolConfigValueProvider',
        'stringConfigValueProvider',
        'intConfigValueProvider',
        'doubleConfigValueProvider',
      ]);
      expect(result.config.detection.keyClasses, ['RemoteConfigKeys']);
      expect(result.validation.isValid, isTrue);
      expect(result.validation.warnings, hasLength(1));
    });

    test('loads yaml overrides from feature_flag_audit.yaml', () async {
      final serviceAccount = File(p.join(tempDir.path, 'service-account.json'));
      await serviceAccount.writeAsString('{}');
      await File(p.join(tempDir.path, 'feature_flag_audit.yaml'))
          .writeAsString('''
feature_flag_audit:
  firebase:
    project_id: demo-project
    service_account_path: ./service-account.json
  scan:
    include:
      - lib
      - packages
    exclude:
      - build
  detection:
    usage_methods:
      - getBool
      - getString
    wrapper_methods:
      - boolConfigValueProvider
    key_classes:
      - AppRemoteConfigKeys
  output:
    show_used: false
    show_summary: true
''');

      final result = await AuditConfigLoader.load(projectRoot: tempDir.path);

      expect(result.loadedFromFile, isTrue);
      expect(result.validation.isValid, isTrue);
      expect(result.config.firebase.projectId, 'demo-project');
      expect(result.config.scan.include, ['lib', 'packages']);
      expect(result.config.scan.exclude, ['build']);
      expect(result.config.detection.keyClasses, ['AppRemoteConfigKeys']);
      expect(result.config.output.showUsed, isFalse);
    });

    test('cli overrides take precedence over yaml values', () async {
      final yamlServiceAccount =
          File(p.join(tempDir.path, 'yaml-account.json'));
      final cliServiceAccount = File(p.join(tempDir.path, 'cli-account.json'));
      await yamlServiceAccount.writeAsString('{}');
      await cliServiceAccount.writeAsString('{}');
      await File(p.join(tempDir.path, 'feature_flag_audit.yaml'))
          .writeAsString('''
feature_flag_audit:
  firebase:
    project_id: yaml-project
    service_account_path: ./yaml-account.json
''');

      final result = await AuditConfigLoader.load(
        projectRoot: tempDir.path,
        projectIdOverride: 'cli-project',
        serviceAccountPathOverride: './cli-account.json',
      );

      expect(result.validation.isValid, isTrue);
      expect(result.config.firebase.projectId, 'cli-project');
      expect(result.config.firebase.serviceAccountPath, './cli-account.json');
    });

    test('reports an error for invalid service account paths', () async {
      await File(p.join(tempDir.path, 'feature_flag_audit.yaml'))
          .writeAsString('''
feature_flag_audit:
  firebase:
    project_id: demo-project
    service_account_path: ./missing.json
''');

      final result = await AuditConfigLoader.load(projectRoot: tempDir.path);

      expect(result.validation.isValid, isFalse);
      expect(
        result.validation.errors.single.message,
        contains('firebase.service_account_path does not exist'),
      );
    });

    test('reports missing project id when firebase config is partially defined',
        () async {
      final serviceAccount = File(p.join(tempDir.path, 'service-account.json'));
      await serviceAccount.writeAsString('{}');
      await File(p.join(tempDir.path, 'feature_flag_audit.yaml'))
          .writeAsString('''
feature_flag_audit:
  firebase:
    service_account_path: ./service-account.json
''');

      final result = await AuditConfigLoader.load(projectRoot: tempDir.path);

      expect(result.validation.isValid, isFalse);
      expect(
        result.validation.errors.single.message,
        contains('Missing required firebase.project_id'),
      );
    });
  });
}
