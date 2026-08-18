import 'package:connectappfe/core/theme/app_colors.dart';
import 'package:connectappfe/core/theme/app_tokens.dart';
import 'package:connectappfe/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// A confirmed rejection, with the optional note the admin typed.
///
/// Wrapping the reason in an object is what distinguishes "rejected, no reason
/// given" from "cancelled the sheet" — a bare `String?` return would collapse
/// the two, and cancelling must not reject anyone.
class RejectDecision {
  const RejectDecision(this.reason);

  /// Null when the admin rejected without explaining.
  final String? reason;
}

/// Asks for an optional rejection reason. Resolves to null if dismissed.
Future<RejectDecision?> showRejectReasonSheet(
  BuildContext context, {
  required String applicantName,
}) {
  return showModalBottomSheet<RejectDecision>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RejectReasonSheet(applicantName: applicantName),
  );
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet({required this.applicantName});

  final String applicantName;

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _reason.text.trim();
    Navigator.of(context).pop(RejectDecision(trimmed.isEmpty ? null : trimmed));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Lifts the sheet clear of the keyboard, which otherwise covers the
      // field the sheet exists to offer.
      padding: EdgeInsets.only(
        left: AppSpacing.gutter,
        right: AppSpacing.gutter,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Reject ${widget.applicantName}?', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'The reason is optional, but it is shown to the applicant — it is '
            'the only thing telling them what to fix before applying again.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Reason (optional)',
            hint: 'e.g. ID card photo is unreadable',
            controller: _reason,
            maxLines: 3,
            // Matches the server's 1-500 rule, so the field can't compose a
            // request the API will reject.
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
