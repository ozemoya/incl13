import 'dart:math';

import 'package:campus_auth/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('email/password flow against the class Firebase project', (
    tester,
  ) async {
    tester.testTextInput.register();
    await app.main();
    await binding.convertFlutterSurfaceToImage();

    Future<void> until(Finder finder) async {
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 80));
        if (finder.evaluate().isNotEmpty) return;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
      }
      expect(finder, findsWidgets);
    }

    Future<void> shot(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await binding.takeScreenshot(name);
    }

    Finder button(String label) => find.widgetWithText(FilledButton, label);
    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }

    String password() {
      final random = Random.secure();
      return 'Lab9!${List.generate(20, (_) => random.nextInt(36).toRadixString(36)).join()}';
    }

    final oldPassword = password();
    final newPassword = password();
    final email =
        'campus13b-${DateTime.now().millisecondsSinceEpoch}@example.com';
    final fields = find.byType(TextFormField);

    await until(button('Sign in'));
    expect(find.text('Your profile'), findsNothing);
    await tap(button('Sign in'));
    await until(find.text('Enter a valid email address.'));
    await shot('01-invalid-input');

    await tap(find.text('Create an account'));
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), oldPassword);
    await tap(button('Create account'));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(button('Create account')).onPressed,
      isNull,
    );
    await until(find.text('Your profile'));
    expect(find.text(email), findsOneWidget);
    await shot('02-registration-profile');

    await tap(find.text('Sign out'));
    await until(button('Sign in'));
    expect(find.text('Your profile'), findsNothing);
    await shot('03-signed-out');

    Future<void> signIn(String secret) async {
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), secret);
      await tap(button('Sign in'));
    }

    await signIn(oldPassword);
    await until(find.text('Your profile'));
    await shot('04-sign-in');
    await tap(find.text('Change password'));
    await tester.enterText(fields.last, newPassword);
    await tap(button('Save new password'));
    await until(find.text('Password updated.'));
    await shot('05-password-updated');
    await tap(find.text('Sign out'));
    await until(button('Sign in'));
    await signIn(oldPassword);
    await until(find.text('Check your credentials and try again.'));
    await shot('06-old-password-rejected');
    await signIn(newPassword);
    await until(find.text('Your profile'));
    expect(find.text(email), findsOneWidget);
    await shot('07-new-password-accepted');
    expect(FirebaseAuth.instance.currentUser?.email, email);
    debugPrint('AUTH FLOW PASSED');
  });
}
