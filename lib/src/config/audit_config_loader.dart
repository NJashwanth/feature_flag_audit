import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'audit_config.dart';
import 'config_issue.dart';

/// Logger callback used during configuration loading.
typedef ConfigLogger = void Function(String message);

/// Result of loading and validating configuration.
final class AuditConfigLoadResult {
  /// Creates a loading result.
  const AuditConfigLoadResult({
    required this.config,
    required this.configFile,
    required this.validation,
    required this.loadedFromFile,
  });

  /// Final merged configuration.
  final AuditConfig config;

  /// The expected config file location.
  final File configFile;

  /// Validation output for [config].
  final ConfigValidationResult validation;

  /// Whether config was loaded from disk.
  final bool loadedFromFile;
}

/// Loads and validates `feature_flag_audit.yaml` from a project root.
final class AuditConfigLoader {
  /// Default configuration file name.
  static const fileName = 'feature_flag_audit.yaml';

  /// Loads configuration from disk, applies CLI overrides, and validates it.
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
