import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_stuff/shared/widgets/permission_dialog.dart';
import 'package:find_my_stuff/shared/services/permission_service.dart';
import 'package:find_my_stuff/shared/models/permission_result.dart';

class MockPermissionService extends PermissionService {
  PermissionResult checkResult;
  PermissionResult requestResult;

  MockPermissionService({
    required this.checkResult,
    required this.requestResult,
  });

  @override
  Future<PermissionResult> checkCameraPermission() async => checkResult;

  @override
  Future<PermissionResult> requestCameraPermission() async => requestResult;

  @override
  Future<PermissionResult> checkGalleryPermission() async => checkResult;

  @override
  Future<PermissionResult> requestGalleryPermission() async => requestResult;

  @override
  Future<void> openSettings() async {}
}

void main() {
  testWidgets('Trace permission request flow - granted', (WidgetTester tester) async {
    final mockService = MockPermissionService(
      checkResult: const PermissionResult(
        state: PermissionState.denied,
        isGranted: false,
        shouldOpenSettings: false,
        message: 'Denied initially',
      ),
      requestResult: const PermissionResult(
        state: PermissionState.granted,
        isGranted: true,
        shouldOpenSettings: false,
        message: 'Granted after request',
      ),
    );

    bool callbackCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await PermissionRequestHelper.request(
                    context: context,
                    service: mockService,
                    type: AppPermissionType.camera,
                    onGranted: () async {
                      callbackCalled = true;
                    },
                  );
                },
                child: const Text('Tap me'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(callbackCalled, isTrue);
  });

  testWidgets('Trace permission request flow - permanently denied', (WidgetTester tester) async {
    final mockService = MockPermissionService(
      checkResult: const PermissionResult(
        state: PermissionState.permanentlyDenied,
        isGranted: false,
        shouldOpenSettings: true,
        message: 'Permanently Denied initially',
      ),
      requestResult: const PermissionResult(
        state: PermissionState.permanentlyDenied,
        isGranted: false,
        shouldOpenSettings: true,
        message: 'Permanently Denied after request',
      ),
    );

    bool callbackCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await PermissionRequestHelper.request(
                    context: context,
                    service: mockService,
                    type: AppPermissionType.camera,
                    onGranted: () async {
                      callbackCalled = true;
                    },
                  );
                },
                child: const Text('Tap me'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap me'));
    await tester.pump(); // Start transition

    expect(find.byType(PermissionDialog), findsOneWidget);
    expect(find.text('Camera Permission Disabled'), findsOneWidget);

    await tester.tap(find.text('Open Settings'));
    await tester.pump();

    // Simulate App Lifecycle Pause & Resume to trigger the observer and complete the check
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(callbackCalled, isFalse);
  });

  testWidgets('Trace gallery permission request flow - granted', (WidgetTester tester) async {
    final mockService = MockPermissionService(
      checkResult: const PermissionResult(
        state: PermissionState.denied,
        isGranted: false,
        shouldOpenSettings: false,
        message: 'Denied initially',
      ),
      requestResult: const PermissionResult(
        state: PermissionState.granted,
        isGranted: true,
        shouldOpenSettings: false,
        message: 'Granted after request',
      ),
    );

    bool callbackCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await PermissionRequestHelper.request(
                    context: context,
                    service: mockService,
                    type: AppPermissionType.gallery,
                    onGranted: () async {
                      callbackCalled = true;
                    },
                  );
                },
                child: const Text('Tap me'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(callbackCalled, isTrue);
  });
}
