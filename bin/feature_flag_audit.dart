import 'dart:io';

import 'package:args/args.dart';
import 'package:feature_flag_audit/feature_flag_audit.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
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
    stdout.writeln('feature_flag_audit v1.0.0');
    stdout.writeln(parser.usage);
    return;
  }

  try {
    final result = await AuditConfigLoader.load(
      projectRoot: Directory.current.path,
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

    final scanResult = await const AuditScanner().scan(
      projectRoot: Directory.current.path,
      config: result.config,
    );

    stdout.writeln('Configuration ready.');
    stdout.writeln(result.config.toMap());

    final formattedOutput = scanResult.formatForCli(
      showUsed: result.config.output.showUsed,
      showSummary: result.config.output.showSummary,
    );
    if (formattedOutput.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln(formattedOutput);
    }
  } on AuditConfigException catch (error) {
    stderr.writeln(error.message);
    exitCode = 78;
  }
}
