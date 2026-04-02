import 'dart:io';

import 'package:feature_flag_audit/feature_flag_audit.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('AuditScanner', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('feature_flag_scanner_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('scans included Dart files and resolves configured key classes',
        () async {
      final libDir = Directory(p.join(tempDir.path, 'lib'));
      await libDir.create(recursive: true);
      await File(p.join(libDir.path, 'remote_config_keys.dart'))
          .writeAsString('''
class RemoteConfigKeys {
  static const welcomeMessage = 'welcome_message';
  static const boolFlag = 'new_checkout_enabled';
}
''');
      await File(p.join(libDir.path, 'feature_usage.dart')).writeAsString('''
void readFlags(remoteConfig) {
  remoteConfig.getBool(RemoteConfigKeys.boolFlag);
  remoteConfig.getString('headline_copy');
  boolConfigValueProvider(RemoteConfigKeys.welcomeMessage);
}
''');

      final result = await const AuditScanner().scan(
        projectRoot: tempDir.path,
        config: AuditConfig.defaults(),
      );

      expect(result.scannedFiles, hasLength(2));
      expect(result.usedKeys, [
        'headline_copy',
        'new_checkout_enabled',
        'welcome_message',
      ]);
      expect(result.findings, hasLength(3));
      expect(result.unresolvedReferences, isEmpty);
      expect(
        result.findings.map((finding) => finding.method),
        containsAll(['getBool', 'getString', 'boolConfigValueProvider']),
      );
    });

    test('skips excluded directories', () async {
      final libDir = Directory(p.join(tempDir.path, 'lib'));
      final buildDir = Directory(p.join(tempDir.path, 'build'));
      await libDir.create(recursive: true);
      await buildDir.create(recursive: true);

      await File(p.join(libDir.path, 'app.dart')).writeAsString('''
void main(remoteConfig) {
  remoteConfig.getBool('active_in_lib');
}
''');
      await File(p.join(buildDir.path, 'generated.dart')).writeAsString('''
void generated(remoteConfig) {
  remoteConfig.getBool('should_not_be_seen');
}
''');

      final config = AuditConfig.defaults().copyWith(
        scan: const ScanConfig(
          include: ['lib', 'build'],
          exclude: ['build'],
        ),
      );

      final result = await const AuditScanner().scan(
        projectRoot: tempDir.path,
        config: config,
      );

      expect(result.scannedFiles, hasLength(1));
      expect(result.usedKeys, ['active_in_lib']);
    });

    test('tracks unresolved key references', () async {
      final libDir = Directory(p.join(tempDir.path, 'lib'));
      await libDir.create(recursive: true);
      await File(p.join(libDir.path, 'app.dart')).writeAsString('''
void main(remoteConfig) {
  remoteConfig.getBool(RemoteConfigKeys.unknownFlag);
}
''');

      final result = await const AuditScanner().scan(
        projectRoot: tempDir.path,
        config: AuditConfig.defaults(),
      );

      expect(result.findings, isEmpty);
      expect(result.unresolvedReferences, hasLength(1));
      expect(
        result.unresolvedReferences.single.reference,
        'RemoteConfigKeys.unknownFlag',
      );
    });
  });
}
