import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'audit_config.dart';
import 'config_issue.dart';

typedef ConfigLogger = void Function(String message);

final class AuditConfigLoadResult {
  const AuditConfigLoadResult({
    required this.config,
    required this.configFile,
    required this.validation,
    required this.loadedFromFile,
  });

  final AuditConfig config;
  final File configFile;
  final ConfigValidationResult validation;
  final bool loadedFromFile;
}

final class AuditConfigLoader {
  static const fileName = 'feature_flag_audit.yaml';

  static Future<AuditConfigLoadResult> load({
    required String projectRoot,
    String? projectIdOverride,
    String? serviceAccountPathOverride,
    bool requireFirebase = false,
    ConfigLogger? infoLogger,
    ConfigLogger? warningLogger,
  }) async {
    final configFile = File(p.join(projectRoot, fileName));
    var config = AuditConfig.defaults();
    var loadedFromFile = false;

    if (await configFile.exists()) {
      loadedFromFile = true;
      infoLogger?.call('Loading configuration from ${configFile.path}.');
      final rawText = await configFile.readAsString();
      final parsed = loadYaml(rawText);

      if (parsed != null && parsed is! YamlMap) {
        throw const AuditConfigException(
          'feature_flag_audit.yaml must contain a top-level YAML map.',
        );
      }

      final rootMap = _toObjectMap(parsed as YamlMap? ?? YamlMap());
      final configSection = rootMap['feature_flag_audit'];

      if (configSection == null) {
        warningLogger?.call(
          'feature_flag_audit.yaml is missing the top-level feature_flag_audit key. Using defaults.',
        );
      } else if (configSection is! Map<Object?, Object?>) {
        throw const AuditConfigException(
          'feature_flag_audit must be a YAML map.',
        );
      } else {
        config = config.mergeMap(configSection, source: 'feature_flag_audit');
      }
    } else {
      infoLogger?.call(
        'No feature_flag_audit.yaml found in $projectRoot. Using default configuration.',
      );
    }

    config = config.mergeCliOverrides(
      projectId: projectIdOverride,
      serviceAccountPath: serviceAccountPathOverride,
    );

    final validation = config.validate(
      projectRoot: projectRoot,
      requireFirebase: requireFirebase,
    );

    for (final warning in validation.warnings) {
      warningLogger?.call(warning.message);
    }

    return AuditConfigLoadResult(
      config: config,
      configFile: configFile,
      validation: validation,
      loadedFromFile: loadedFromFile,
    );
  }
}

Map<Object?, Object?> _toObjectMap(YamlMap yamlMap) {
  final result = <Object?, Object?>{};
  for (final entry in yamlMap.entries) {
    result[entry.key] = _convertYamlValue(entry.value);
  }
  return result;
}

Object? _convertYamlValue(Object? value) {
  if (value is YamlMap) {
    return _toObjectMap(value);
  }
  if (value is YamlList) {
    return value.map(_convertYamlValue).toList(growable: false);
  }
  return value;
}
