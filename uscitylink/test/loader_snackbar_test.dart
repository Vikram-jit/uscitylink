import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:uscitylink/utils/utils.dart';

/// Regression: a wrong password shows an error snackbar. Logging in again while that snackbar
/// is still visible used to leave the loader stuck, because Get.back() closed the snackbar
/// instead of the loader dialog.
void main() {
  testWidgets('hideLoader closes the loader while an error snackbar is showing', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));

    // First wrong password
    Utils.showLoader();
    await tester.pump(const Duration(milliseconds: 300));
    Utils.hideLoader();
    Utils.snackBar('Error', 'Invalid credentials');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(Get.isSnackbarOpen, isTrue);

    // Second wrong password, snackbar still on screen
    Utils.showLoader();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    Utils.hideLoader();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(Get.isDialogOpen, isFalse);

    // Let snackbar timers finish
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
