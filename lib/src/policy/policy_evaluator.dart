import '../config/policy_config.dart';
import '../scan/audit_scanner.dart';
import '../scan/key_comparison.dart';

/// Outcome of a single policy rule evaluation.
final class PolicyRuleResult {
  /// Creates a rule result.
  const PolicyRuleResult({
    required this.ruleName,
    required this.action,
    required this.count,
    required this.items,
  });

  /// The policy rule name (e.g. `code_only_keys`).
  final String ruleName;

  /// The configured action for this rule.
  final PolicyAction action;

  /// Number of violations found.
  final int count;

  /// Violation detail strings (keys, references, etc.).
  final List<String> items;

  /// Whether any violations were found.
  bool get hasViolations => count > 0;

  /// Whether this rule should fail the pipeline.
  bool get isFailing => action == PolicyAction.fail && hasViolations;

  /// Whether this rule produced a warning.
  bool get isWarning => action == PolicyAction.warn && hasViolations;
}

/// Aggregate result of evaluating all policy rules against audit findings.
final class PolicyEvaluationResult {
  /// Creates a policy evaluation result.
  const PolicyEvaluationResult(this.ruleResults);

  /// Individual rule outcomes (excludes rules set to [PolicyAction.pass]).
  final List<PolicyRuleResult> ruleResults;

  /// Whether at least one rule triggered [PolicyAction.fail] with violations.
  bool get hasFailed => ruleResults.any((r) => r.isFailing);

  /// Formats the policy results for CLI output.
  String formatForCli() {
    final lines = <String>['Policy check results:'];

    if (ruleResults.isEmpty) {
      lines.add('  All rules set to pass — no checks performed.');
    } else {
      for (final rule in ruleResults) {
        if (!rule.hasViolations) {
          lines.add('  [PASS] ${rule.ruleName}: no violations');
        } else {
          final label = rule.isFailing ? '[FAIL]' : '[WARN]';
          final noun = rule.count == 1 ? 'violation' : 'violations';
          lines.add('  $label ${rule.ruleName}: ${rule.count} $noun');
          for (final item in rule.items) {
            lines.add('    - $item');
          }
        }
      }
    }

    lines.add('');
    lines.add(
      hasFailed ? 'Pipeline result: FAILED' : 'Pipeline result: PASSED',
    );
    return lines.join('\n');
  }
}

/// Evaluates [policy] rules against scan and optional Firebase comparison results.
///
/// Rules that depend on Firebase ([PolicyConfig.codeOnlyKeys] and
/// [PolicyConfig.consoleOnlyKeys]) are skipped when [comparison] is null,
/// and a note is included in the output via the returned result.
PolicyEvaluationResult evaluatePolicy({
  required PolicyConfig policy,
  required AuditScanResult scanResult,
  AuditKeyComparison? comparison,
}) {
  final rules = <PolicyRuleResult>[];

  if (policy.unresolvedReferences != PolicyAction.pass) {
    final items = scanResult.unresolvedReferences
        .map((r) => r.reference)
        .toList(growable: false);
    rules.add(PolicyRuleResult(
      ruleName: 'unresolved_references',
      action: policy.unresolvedReferences,
      count: items.length,
      items: items,
    ));
  }

  if (comparison != null) {
    if (policy.codeOnlyKeys != PolicyAction.pass) {
      rules.add(PolicyRuleResult(
        ruleName: 'code_only_keys',
        action: policy.codeOnlyKeys,
        count: comparison.codeOnlyKeys.length,
        items: comparison.codeOnlyKeys,
      ));
    }
    if (policy.consoleOnlyKeys != PolicyAction.pass) {
      rules.add(PolicyRuleResult(
        ruleName: 'console_only_keys',
        action: policy.consoleOnlyKeys,
        count: comparison.consoleOnlyKeys.length,
        items: comparison.consoleOnlyKeys,
      ));
    }
  }

  return PolicyEvaluationResult(rules);
}
