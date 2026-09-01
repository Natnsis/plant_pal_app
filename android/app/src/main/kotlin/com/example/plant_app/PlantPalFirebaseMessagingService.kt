package com.example.plant_app

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Receives FCM messages from the PlantPal backend (see
 * internals/services/push.go). Messages are data-only, so this runs for
 * every message — foreground, background, or after the app was swiped away —
 * and builds the visible notification itself via [Notifications.post],
 * reusing the exact styling/channel of the in-app path.
 *
 * Registered in AndroidManifest.xml. Firebase is configured without the
 * google-services Gradle plugin: the values live in res/values/firebase.xml
 * as string resources, which FirebaseInitProvider reads at process start.
 */
class PlantPalFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        val title = data["title"]?.takeIf { it.isNotBlank() } ?: "PlantPal"
        val body = data["body"] ?: ""

        // Stable id per notification item so the same reminder doesn't stack
        // duplicates; fall back to a rolling id when the payload has none.
        val id = data["notif_id"]?.toIntOrNull()
            ?: (System.currentTimeMillis() % 100000).toInt()

        Notifications.post(applicationContext, id, title, body, data["action_url"])
    }

    override fun onNewToken(token: String) {
        // Best effort: if a Flutter engine is alive, hand the fresh token to
        // Dart so it can re-register immediately. Otherwise the Dart side
        // picks it up via PushChannel.getToken() on the next app start /
        // resume, so nothing is lost here.
        MainActivity.pushChannel?.invokeMethod("onToken", token)
    }
}
