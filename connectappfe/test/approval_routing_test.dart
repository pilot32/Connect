import 'package:connectappfe/core/models/models.dart';
import 'package:connectappfe/core/router/app_router.dart';
import 'package:connectappfe/core/router/app_routes.dart';
import 'package:connectappfe/features/admin/models/applicant.dart';
import 'package:connectappfe/features/auth/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the admin-approval gate on the client.
///
/// Two things are worth locking down here. The parsing has to *fail closed* —
/// an unrecognised role must not become an admin and an unrecognised status
/// must not become approved — and the redirect table has to route three
/// audiences to three homes without stranding any of them. Both are pure
/// functions precisely so they can be checked without a backend.
void main() {
  group('UserRole.parse', () {
    test('reads the two known roles', () {
      expect(UserRole.parse('admin'), UserRole.admin);
      expect(UserRole.parse('user'), UserRole.user);
    });

    test('falls back to the narrower role for anything unrecognised', () {
      // A typo, a future role, or a missing field must never hand out the
      // admin console.
      expect(UserRole.parse(null), UserRole.user);
      expect(UserRole.parse(''), UserRole.user);
      expect(UserRole.parse('Admin'), UserRole.user);
      expect(UserRole.parse('superadmin'), UserRole.user);
    });
  });

  group('AccountStatus.parse', () {
    test('reads the three known statuses', () {
      expect(AccountStatus.parse('pending'), AccountStatus.pending);
      expect(AccountStatus.parse('approved'), AccountStatus.approved);
      expect(AccountStatus.parse('rejected'), AccountStatus.rejected);
    });

    test('treats an unrecognised server value as not yet cleared', () {
      expect(AccountStatus.parse(null), AccountStatus.pending);
      expect(AccountStatus.parse('suspended'), AccountStatus.pending);
      expect(AccountStatus.parse('Approved'), AccountStatus.pending);
    });

    test('a missing *stored* status is unknown, not pending', () {
      // Restoring a session saved before approval existed. Those accounts were
      // grandfathered to approved server-side, so reading the absent key as
      // "pending" would park a working account in the waiting room.
      expect(AccountStatus.restore(null), AccountStatus.unknown);
      expect(AccountStatus.restore('approved'), AccountStatus.approved);
    });

    test('round-trips through storage', () {
      for (final status in AccountStatus.values) {
        if (status == AccountStatus.unknown) continue;
        expect(AccountStatus.restore(status.wire), status);
      }
      expect(UserRole.parse(UserRole.admin.wire), UserRole.admin);
    });
  });

  group('AuthUser.fromJson', () {
    test('reads a pending signup response', () {
      final user = AuthUser.fromJson(<String, dynamic>{
        'id': '6c9bdf39-ea7c-4c93-97f1-69296a42e5ef',
        'email': 'officer@example.com',
        'role': 'user',
        'status': 'pending',
        'rejectionReason': null,
        'createdAt': '2026-08-17T14:04:00.845Z',
      });

      expect(user.id, '6c9bdf39-ea7c-4c93-97f1-69296a42e5ef');
      expect(user.email, 'officer@example.com');
      expect(user.isAdmin, isFalse);
      expect(user.isPending, isTrue);
      expect(user.isApproved, isFalse);
      expect(user.rejectionReason, isNull);
    });

    test('reads an admin login response', () {
      final user = AuthUser.fromJson(<String, dynamic>{
        'id': 'c6804a74-97a3-4989-ba22-97eed48b7c69',
        'email': 'admin@govconnect.in',
        'role': 'admin',
        'status': 'approved',
      });

      expect(user.isAdmin, isTrue);
      expect(user.isApproved, isTrue);
    });

    test('carries the rejection reason through', () {
      final user = AuthUser.fromJson(<String, dynamic>{
        'id': 'x',
        'email': 'officer@example.com',
        'role': 'user',
        'status': 'rejected',
        'rejectionReason': 'ID card photo is unreadable',
      });

      expect(user.isRejected, isTrue);
      expect(user.rejectionReason, 'ID card photo is unreadable');
    });

    test('an empty payload is a pending non-admin', () {
      final user = AuthUser.fromJson(<String, dynamic>{});
      expect(user.isAdmin, isFalse);
      expect(user.isApproved, isFalse);
    });
  });

  group('Applicant.fromJson', () {
    test('reads the admin list payload, ID card included', () {
      final applicant = Applicant.fromJson(<String, dynamic>{
        'id': '6c9bdf39-ea7c-4c93-97f1-69296a42e5ef',
        'email': 'officer@example.com',
        'role': 'user',
        'status': 'pending',
        'idCardPhotoUrl': 'https://res.cloudinary.com/x/id-cards/y.png',
        'rejectionReason': null,
        'reviewedAt': null,
        'createdAt': '2026-08-17T14:04:00.845Z',
        'updatedAt': '2026-08-17T14:04:00.845Z',
        'profile': <String, dynamic>{
          'name': 'Approval Test Officer',
          'photoUrl': null,
          'designation': 'District Magistrate',
          'service': 'IAS',
          'department': 'Revenue',
          'stateOrCadre': 'Karnataka',
          'yearsInService': 5,
          'bio': null,
        },
      });

      expect(applicant.status, AccountStatus.pending);
      expect(applicant.hasIdCard, isTrue);
      expect(applicant.displayName, 'Approval Test Officer');
      expect(applicant.profile?.service, 'IAS');
      expect(applicant.createdAt, isNotNull);
      expect(applicant.reviewedAt, isNull);
    });

    test('survives a missing profile and a missing ID card', () {
      final applicant = Applicant.fromJson(<String, dynamic>{
        'id': 'x',
        'email': 'officer@example.com',
        'status': 'approved',
        'profile': null,
      });

      expect(applicant.profile, isNull);
      expect(applicant.displayName, 'Unknown official');
      // Drives the "no ID card on file" warning rather than a broken image.
      expect(applicant.hasIdCard, isFalse);
    });
  });

  group('ApplicantFilter', () {
    test('each tab claims only its own status, and All claims every one', () {
      expect(ApplicantFilter.pending.matches(AccountStatus.pending), isTrue);
      expect(ApplicantFilter.pending.matches(AccountStatus.approved), isFalse);
      expect(ApplicantFilter.approved.matches(AccountStatus.approved), isTrue);
      expect(ApplicantFilter.rejected.matches(AccountStatus.rejected), isTrue);
      expect(ApplicantFilter.rejected.matches(AccountStatus.pending), isFalse);

      for (final status in AccountStatus.values) {
        expect(ApplicantFilter.all.matches(status), isTrue);
      }
    });

    test('wire values match the API query parameter', () {
      expect(ApplicantFilter.pending.wire, 'pending');
      expect(ApplicantFilter.all.wire, 'all');
    });
  });

  group('resolveRedirect', () {
    String? go(
      String location, {
      AuthStatus status = AuthStatus.authenticated,
      bool isAdmin = false,
      bool isAwaitingApproval = false,
    }) => resolveRedirect(
      location: location,
      status: status,
      isAdmin: isAdmin,
      isAwaitingApproval: isAwaitingApproval,
    );

    test('holds everything on the splash while the session is restoring', () {
      expect(go(AppRoutes.splash, status: AuthStatus.unknown), isNull);
      expect(
        go(AppRoutes.feed, status: AuthStatus.unknown),
        AppRoutes.splash,
      );
      expect(
        go(AppRoutes.login, status: AuthStatus.unknown),
        AppRoutes.splash,
      );
    });

    test('sends each audience to its own home from the splash', () {
      expect(
        go(AppRoutes.splash, status: AuthStatus.unauthenticated),
        AppRoutes.login,
      );
      expect(go(AppRoutes.splash, isAdmin: true), AppRoutes.admin);
      expect(
        go(AppRoutes.splash, isAwaitingApproval: true),
        AppRoutes.pendingApproval,
      );
      expect(go(AppRoutes.splash), AppRoutes.afterLogin);
    });

    test('leaves the auth screens alone even once signed in', () {
      // The login and signup screens navigate themselves after their success
      // animation; yanking them away mid-animation is the bug this prevents.
      expect(go(AppRoutes.login), isNull);
      expect(go(AppRoutes.signup), isNull);
      expect(go(AppRoutes.login, isAdmin: true), isNull);
      expect(
        go(AppRoutes.signup, status: AuthStatus.unauthenticated),
        isNull,
      );
    });

    test('everything else needs a session', () {
      for (final location in <String>[
        AppRoutes.feed,
        AppRoutes.profile,
        AppRoutes.admin,
        AppRoutes.pendingApproval,
      ]) {
        expect(
          go(location, status: AuthStatus.unauthenticated),
          AppRoutes.login,
          reason: '$location must require a session',
        );
      }
    });

    test('an admin is pinned to the console', () {
      expect(go(AppRoutes.admin, isAdmin: true), isNull);
      for (final location in <String>[
        AppRoutes.feed,
        AppRoutes.search,
        AppRoutes.network,
        AppRoutes.profile,
        AppRoutes.pendingApproval,
      ]) {
        expect(
          go(location, isAdmin: true),
          AppRoutes.admin,
          reason: 'an admin has no business on $location',
        );
      }
    });

    test('the console is closed to everyone else', () {
      expect(go(AppRoutes.admin), AppRoutes.afterLogin);
      expect(
        go(AppRoutes.admin, isAwaitingApproval: true),
        AppRoutes.pendingApproval,
      );
    });

    test('an unapproved user is held in the waiting room', () {
      expect(go(AppRoutes.pendingApproval, isAwaitingApproval: true), isNull);
      for (final location in <String>[
        AppRoutes.feed,
        AppRoutes.search,
        AppRoutes.network,
        AppRoutes.profile,
        AppRoutes.editProfile,
        AppRoutes.composePost,
      ]) {
        expect(
          go(location, isAwaitingApproval: true),
          AppRoutes.pendingApproval,
          reason: '$location must be gated behind approval',
        );
      }
    });

    test('approval releases them, on the token they already hold', () {
      // The status refresh flips isAwaitingApproval to false and the router
      // re-runs — this is the step that gets an approved user into the app
      // without signing in again.
      expect(go(AppRoutes.pendingApproval), AppRoutes.afterLogin);
      expect(go(AppRoutes.feed), isNull);
      expect(go(AppRoutes.profile), isNull);
    });

    test('an unknown status is let through rather than gated', () {
      // A legacy stored session: not *known* to be unapproved, and the
      // background refresh will settle it a moment later. The server still
      // gates the data, so letting them through costs nothing.
      final user = AuthUser.fromJson(<String, dynamic>{'id': 'x'});
      expect(user.status, AccountStatus.pending);

      const restored = AuthUser(
        id: 'x',
        email: 'officer@example.com',
      );
      expect(restored.status, AccountStatus.unknown);
      expect(restored.isPending, isFalse);
      expect(restored.isRejected, isFalse);
    });
  });
}
