import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;

import '../config/config_issue.dart';

/// Loads Firebase Remote Config keys from the remote template API.
final class FirebaseRemoteConfigClient {
  /// Creates a Firebase Remote Config client.
  const FirebaseRemoteConfigClient();

  /// Fetches parameter keys from Firebase Remote Config for [projectId].
  ///
  /// [serviceAccountPath] can be absolute or relative to [projectRoot].
  Future<List<String>> fetchParameterKeys({
    required String projectId,
    required String serviceAccountPath,
    required String projectRoot,
  }) async {
    final resolvedServiceAccountPath = p.normalize(
      p.isAbsolute(serviceAccountPath)
          ? serviceAccountPath
          : p.join(projectRoot, serviceAccountPath),
    );

    final file = File(resolvedServiceAccountPath);
    if (!await file.exists()) {
      throw AuditConfigException(
        'Service account file does not exist: $resolvedServiceAccountPath',
      );
    }

    final jsonText = await file.readAsString();
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const AuditConfigException(
        'service_account_path must point to a valid JSON object.',
      );
    }

    final credentials = ServiceAccountCredentials.fromJson(decoded);
    final client = await clientViaServiceAccount(
      credentials,
      const [
        'https://www.googleapis.com/auth/firebase.remoteconfig',
        'https://www.googleapis.com/auth/cloud-platform.read-only',
      ],
    );

    try {
      final uri = Uri.parse(
          'https://firebaseremoteconfig.googleapis.com/v1/projects/$projectId/remoteConfig');
      final response =
          await client.get(uri, headers: const {'Accept': 'application/json'});

      if (response.statusCode != 200) {
        throw AuditConfigException(
          'Unable to fetch Firebase Remote Config template '
          '(HTTP ${response.statusCode}). Response: ${response.body}',
        );
      }

      final templateJson = jsonDecode(response.body);
      if (templateJson is! Map<String, dynamic>) {
        throw const AuditConfigException(
          'Unexpected Firebase Remote Config template response format.',
        );
      }

      final parameters = templateJson['parameters'];
      if (parameters is! Map<String, dynamic>) {
        return const <String>[];
      }

      final keys = parameters.keys.toList()..sort();
      return List.unmodifiable(keys);
    } finally {
      client.close();
    }
  }
}
