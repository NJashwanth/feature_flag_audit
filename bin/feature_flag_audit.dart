import 'dart:io';

import 'package:args/args.dart';
import 'package:feature_flag_audit/feature_flag_audit.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'project-root',
      help:
          'Path to the target Flutter project root. Defaults to current directory.',
    )
    ..addOption(
      'project-id',
      help: 'Override firebase.project_id from feature_flag_audit.yaml.',
    )
    ..addOption(
      'service-account',
      help:
          'Override firebase.service_account_path from feature_flag_audit.yaml.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show command usage.',
    );

  late final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln('Invalid arguments: ${error.message}');
    stderr.writeln(parser.usage);
    exitCode = 64;
    return;
  }

  if (args['help'] as bool) {
    stdout.writeln('feature_flag_audit v1.2.0');
    stdout.writeln(parser.usage);
    return;
  }

  try {
    final projectRoot =
        (args['project-root'] as String?)?.trim().isNotEmpty == true
            ? args['project-root'] as String
            : Directory.current.path;

    final result = await AuditConfigLoader.load(
      projectRoot: projectRoot,
      projectIdOverride: args['project-id'] as String?,
      serviceAccountPathOverride: args['service-account'] as String?,
      infoLogger: stdout.writeln,
      warningLogger: stderr.writeln,
    );

    if (!result.validation.isValid) {
      for (final error in result.validation.errors) {
        stderr.writeln(error.message);
      }
      exitCode = 78;
      return;
    }

    stdout.writeln('Configuration ready.');

    final scanResult = await const AuditScanner().scan(
      projectRoot: projectRoot,
      config: result.config,
    );

    final formattedOutput = scanResult.formatForCli(
      showUsed: result.config.output.showUsed,
      showSummary: result.config.output.showSummary,
      showUnresolvedReferences: result.config.output.showUnresolvedReferences,
    );
    if (formattedOutput.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln(formattedOutput);
    }

    final firebaseProjectId = result.config.firebase.projectId;
    final firebaseServiceAccountPath =
        result.config.firebase.serviceAccountPath;
    final shouldCompareWithConsole = firebaseProjectId != null &&
        firebaseProjectId.isNotEmpty &&
        firebaseServiceAccountPath != null &&
        firebaseServiceAccountPath.isNotEmpty;

    if (shouldCompareWithConsole) {
      stdout.writeln('');
      stdout.writeln('Fetching Firebase Remote Config template...');
      try {
        final consoleKeys =
            await const FirebaseRemoteConfigClient().fetchParameterKeys(
          projectId: firebaseProjectId,
          serviceAccountPath: firebaseServiceAccountPath,
          projectRoot: projectRoot,
        );

        final comparison = AuditKeyComparison.compare(
          consoleKeys: consoleKeys.toSet(),
          codeKeys: scanResult.usedKeys.toSet(),
        );
        final comparisonOutput = comparison.formatForCli(
          showSummary: result.config.output.showFirebaseSummary,
          showConsoleOnly: result.config.output.showFirebaseConsoleOnly,
          showCodeOnly: result.config.output.showFirebaseCodeOnly,
        );
        if (comparisonOutput.isNotEmpty) {
          stdout.writeln(comparisonOutput);
        }
      } on AuditConfigException catch (error) {
        stderr.writeln('Firebase comparison skipped: ${error.message}');
      } catch (error) {
        stderr.writeln('Firebase comparison skipped: $error');
      }
    }
  } on AuditConfigException catch (error) {
    stderr.writeln(error.message);
    exitCode = 78;
  }
}
