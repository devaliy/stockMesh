import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the Hub process alive (design.md §9): a `dataSync` foreground
/// service with the persistent "StockMesh Hub" notification.
///
/// The ServerSocket itself runs in the main isolate (single database
/// connection, single sequencer — invariant §1.2 needs exactly one writer);
/// this service exists so Android never kills that isolate.
abstract final class HubForeground {
  static bool _initialized = false;

  static void _ensureInit() {
    if (_initialized) return;
    _initialized = true;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'stockmesh_hub',
        channelName: 'StockMesh Hub',
        channelDescription:
            'Keeps the shop server running while the screen is off',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
  }

  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    _ensureInit();
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'StockMesh Hub',
      notificationText: 'Running — 0 devices connected',
      callback: hubServiceCallback,
    );
  }

  static Future<void> updateConnectedCount(int count) async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: 'StockMesh Hub',
      notificationText:
          'Running — $count device${count == 1 ? '' : 's'} connected',
    );
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// §9: ask the user to exempt the Hub from battery optimization, with the
  /// plain-language rationale shown by the caller beforehand.
  static Future<void> requestBatteryExemption() async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  static Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }
}

@pragma('vm:entry-point')
void hubServiceCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveHandler());
}

/// Deliberately inert: the service's only job is to hold the process.
class _KeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
