package com.example.plant_app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * One place that actually posts a notification to the system shade, shared
 * by the two callers that need it:
 *
 *  - `MainActivity`'s `plantpal/notifications` "show" method  (the app is
 *    open and polled the inbox itself), and
 *  - `PlantPalFirebaseMessagingService.onMessageReceived`     (an FCM data
 *    push arrived, app may be backgrounded or dead).
 *
 * Both paths build an identical notification so styling / channel / tap
 * behaviour never drift apart.
 */
object Notifications {
    const val CHANNEL_ID = "plantpal_care"

    /** Intent extra carrying a `plantpal://…` deep link from a tapped
     *  notification; read by MainActivity and forwarded to the link channel. */
    const val EXTRA_LINK = "pp_link"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (mgr.getNotificationChannel(CHANNEL_ID) == null) {
                mgr.createNotificationChannel(
                    NotificationChannel(
                        CHANNEL_ID,
                        "Plant care reminders",
                        NotificationManager.IMPORTANCE_DEFAULT,
                    ).apply { description = "Watering, feeding and check-up reminders" }
                )
            }
        }
    }

    /** Posts the notification, or silently no-ops if POST_NOTIFICATIONS is
     *  not granted (Android 13+). [link] is an optional `plantpal://…` deep
     *  link opened when the notification is tapped. */
    fun post(context: Context, id: Int, title: String, body: String, link: String? = null) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        ensureChannel(context)

        val tapIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (!link.isNullOrBlank()) putExtra(EXTRA_LINK, link)
        }
        val pending = PendingIntent.getActivity(
            context, id, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pending)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }
}
