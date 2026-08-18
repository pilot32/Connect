import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/theme/app_theme.dart';
import 'package:connectappfe/features/admin/models/applicant.dart';
import 'package:connectappfe/features/admin/widgets/applicant_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The card decides which decisions are still open for a given applicant.
///
/// Offering "Approve" on an already-approved account would be a button that
/// visibly does nothing, and losing the reconsider path on a rejected one would
/// make a rejection permanent in the UI even though the API allows it — so the
/// per-status button rules are worth pinning rather than eyeballing.
///
/// `Image.network` fails under the test HTTP client; both call sites hand it an
/// `errorBuilder`, which is exactly what keeps these pumps from throwing.
void main() {
  Applicant build(AccountStatus status, {String? idCardPhotoUrl}) {
    return Applicant(
      id: 'a1',
      email: 'officer@example.com',
      status: status,
      idCardPhotoUrl: idCardPhotoUrl,
      profile: const UserProfile(
        name: 'Approval Test Officer',
        designation: 'District Magistrate',
        service: 'IAS',
        department: 'Revenue',
        stateOrCadre: 'Karnataka',
        yearsInService: 5,
      ),
      createdAt: DateTime.utc(2026, 8, 17, 14, 4),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    Applicant applicant, {
    bool busy = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ApplicantCard(
              applicant: applicant,
              busy: busy,
              onApprove: () {},
              onReject: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a pending applicant can be approved or rejected', (
    tester,
  ) async {
    await pump(tester, build(AccountStatus.pending));

    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('an approved applicant offers only rejection', (tester) async {
    await pump(tester, build(AccountStatus.approved));

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
  });

  testWidgets('a rejected applicant can be reconsidered, not re-rejected', (
    tester,
  ) async {
    await pump(tester, build(AccountStatus.rejected));

    expect(find.text('Reject'), findsNothing);
    // Worded differently from a first-time approval so the admin can see they
    // are overturning an earlier decision.
    expect(find.text('Approve anyway'), findsOneWidget);
  });

  testWidgets('shows the applicant details a decision rests on', (
    tester,
  ) async {
    await pump(tester, build(AccountStatus.pending));

    expect(find.text('Approval Test Officer'), findsOneWidget);
    expect(find.text('District Magistrate'), findsOneWidget);
    expect(find.text('IAS'), findsOneWidget);
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Karnataka'), findsOneWidget);
    expect(find.text('5 yrs in service'), findsOneWidget);
    expect(find.text('officer@example.com'), findsOneWidget);
  });

  testWidgets('offers the ID card when there is one', (tester) async {
    await pump(
      tester,
      build(
        AccountStatus.pending,
        idCardPhotoUrl: 'https://res.cloudinary.com/x/id-cards/y.png',
      ),
    );

    expect(find.text('View government ID card'), findsOneWidget);
  });

  testWidgets('warns instead of offering a broken viewer when there is none', (
    tester,
  ) async {
    await pump(tester, build(AccountStatus.pending));

    expect(find.text('View government ID card'), findsNothing);
    expect(
      find.textContaining('No ID card on file'),
      findsOneWidget,
    );
  });

  testWidgets('both actions are disabled while a decision is in flight', (
    tester,
  ) async {
    await pump(tester, build(AccountStatus.pending), busy: true);

    final approve = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Approve'),
    );
    final reject = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Reject'),
    );

    expect(approve.onPressed, isNull);
    expect(reject.onPressed, isNull);
  });
}
