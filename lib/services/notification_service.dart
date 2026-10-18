import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationPermission { unknown, granted, denied, unsupported }

/// System notifications (Android, iOS, macOS, Windows, Linux and web).
///
/// Every call is best-effort: if the platform has no support or the user
/// declined, the app still shows its in-app banner.
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  final permission = ValueNotifier(NotificationPermission.unknown);

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'arrivals',
      'Chegadas de ônibus',
      channelDescription: 'Avisa quando um ônibus favorito está chegando.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          linux: LinuxInitializationSettings(defaultActionName: 'Abrir'),
          windows: WindowsInitializationSettings(
            appName: 'OneBus',
            appUserModelId: 'com.onebus.app',
            guid: '5c0f3a8e-6f1d-4b8a-9d2e-3a7b1c9e4f20',
          ),
        ),
      );
      _ready = true;
      permission.value = await _currentPermission();
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
      permission.value = NotificationPermission.unsupported;
    }
  }

  Future<NotificationPermission> _currentPermission() async {
    if (kIsWeb) {
      final web = _plugin
          .resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin
          >();
      return switch (web?.permissionStatus) {
        WebNotificationPermission.granted => NotificationPermission.granted,
        WebNotificationPermission.denied => NotificationPermission.denied,
        null => NotificationPermission.unsupported,
        _ => NotificationPermission.unknown,
      };
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled == true
          ? NotificationPermission.granted
          : NotificationPermission.unknown;
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return NotificationPermission.granted;
    }
    return NotificationPermission.unknown;
  }

  /// Asks the OS/browser. Must be called from a user tap (browsers block
  /// prompts that aren't triggered by a gesture).
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    bool? granted;
    try {
      if (kIsWeb) {
        granted = await _plugin
            .resolvePlatformSpecificImplementation<
              WebFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            granted = await _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission();
          case TargetPlatform.iOS:
            granted = await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true);
          case TargetPlatform.macOS:
            granted = await _plugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true);
          default:
            granted = true;
        }
      }
    } catch (_) {
      granted = false;
    }
    permission.value = granted == true
        ? NotificationPermission.granted
        : NotificationPermission.denied;
    return granted == true;
  }

  Future<void> show(int id, String title, String body) async {
    if (!_ready || permission.value != NotificationPermission.granted) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}
