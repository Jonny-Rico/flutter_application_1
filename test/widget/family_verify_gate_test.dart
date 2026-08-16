import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/domain/user_profile.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/family/presentation/screens/family_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = UserProfile(
    userId: 'qa-a',
    displayName: 'QA User A',
    email: 'qa.a.familytasks@example.com',
  );

  testWidgets('VER-N-01: unverified user sees verify gate, not create/join', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          emailVerifiedProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: FamilyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verify email to use Family'), findsOneWidget);
    expect(find.text('Create as owner'), findsNothing);
    expect(find.text('Join with code'), findsNothing);
  });

  testWidgets('VER-P-01: verified user sees create/join', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          emailVerifiedProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(home: FamilyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create as owner'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Join with code'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Join with code'), findsOneWidget);
    expect(find.text('Verify email to use Family'), findsNothing);
  });
}
