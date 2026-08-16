import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging wrapper.
///
/// Safe to call even before Firebase is configured (no google-services.json
/// yet): every operation is wrapped in try/catch, so the app keeps working
/// and pushes activate automatically after the Firebase setup + rebuild.
///
/// Topic model: the app subscribes to "alerts"; the CalCity manage panel
/// publishes alerts to that topic (POST /manage/alerts/{id}/push/).
class PushService {
  static final PushService _instance = PushService._();
  factory PushService() => _instance;
  PushService._();

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;

      // Android 13+ requires runtime notification permission.
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // User declined — the app still works, just no notifications.
      }

      // Topic subscriptions: community alerts + news/events digests.
      await messaging.subscribeToTopic('alerts');
      await messaging.subscribeToTopic('news');
      await messaging.subscribeToTopic('events');

      // Foreground messages (v1: silent; v2: heads-up banner via
      // flutter_local_notifications if we want in-app display).
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // no-op — background/terminated pushes still display natively.
      });

      _ready = true;
    } catch (_) {
      // Firebase not configured on this build — nothing to do.
      _ready = false;
    }
  }
}
