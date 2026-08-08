"""
Firebase Cloud Messaging (FCM) push notifications for CalCity.

Sends topic-based notifications to the mobile app. The Flutter app
subscribes to the "alerts" topic (and "news"); the backend publishes to
/topics/alerts — no device tokens need to be stored server-side.

Configuration (all optional — the module is a safe no-op when unset):
  FIREBASE_SERVICE_ACCOUNT_PATH  path to the service-account JSON file on PA
                                 (e.g. /home/MMSantelopevalley/calcity-app/firebase-service-account.json)
  FIREBASE_SERVICE_ACCOUNT_JSON  the JSON content inline (alternative to PATH)
  FIREBASE_TOPIC                 default publish topic (default: "alerts")

Usage:
    from community.firebase_messaging import send_topic_message
    ok, err = send_topic_message("Road closure on Randsburg", "Alert text...", topic="alerts")
"""
import json
import logging
import os
from typing import Optional

logger = logging.getLogger("firebase_messaging")

_APP = None


def _get_app():
    """Lazily initialize the Firebase app once. Returns None if not configured."""
    global _APP
    if _APP is not None:
        return _APP

    path = os.environ.get("FIREBASE_SERVICE_ACCOUNT_PATH", "")
    inline = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "")

    creds = None
    if path and os.path.exists(path):
        try:
            from firebase_admin import credentials
            creds = credentials.Certificate(path)
        except Exception as e:
            logger.warning("FCM: bad service account file %s: %s", path, e)
            return None
    elif inline:
        try:
            from firebase_admin import credentials
            creds = credentials.Certificate(json.loads(inline))
        except Exception as e:
            logger.warning("FCM: bad FIREBASE_SERVICE_ACCOUNT_JSON: %s", e)
            return None
    else:
        logger.info("FCM not configured (no FIREBASE_SERVICE_ACCOUNT_* env)")
        return None

    try:
        import firebase_admin
        _APP = firebase_admin.initialize_app(creds)
        logger.info("FCM initialized for project %s", _APP.project_id)
        return _APP
    except Exception as e:
        logger.warning("FCM init failed: %s", e)
        return None


def send_topic_message(title: str, body: str, topic: str = "alerts",
                       data: Optional[dict] = None) -> tuple:
    """
    Publish a notification to an FCM topic.

    Returns (True, message_id) on success, (False, error) on failure.
    Safe to call when FCM is not configured — returns (False, reason)
    without raising.
    """
    app = _get_app()
    if app is None:
        return False, "FCM not configured"

    try:
        from firebase_admin import messaging
        message = messaging.Message(
            topic=topic,
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
        )
        response = messaging.send(message)
        return True, response
    except Exception as e:
        logger.error("FCM send failed (topic=%s): %s", topic, e)
        return False, str(e)
