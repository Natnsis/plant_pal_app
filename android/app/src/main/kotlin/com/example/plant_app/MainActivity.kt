package com.example.plant_app

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.InputStream

/**
 * Native bridges hand-rolled because the stripped Flutter SDK on this machine
 * can't resolve `image_picker` or `flutter_local_notifications` (both force
 * ancient versions that don't build against AGP 9).
 *
 *  - `plantpal/media`         : system camera app (via FileProvider, no CAMERA
 *                               permission) + system photo picker -> JPEG bytes.
 *  - `plantpal/notifications` : POST_NOTIFICATIONS permission flow + posting
 *                               real notifications to the phone's shade.
 *
 * See lib/api/media_channel.dart and lib/api/notif_channel.dart.
 */
class MainActivity : FlutterActivity() {
    private val mediaChannelName = "plantpal/media"
    private val notifChannelName = "plantpal/notifications"
    private val linkChannelName = "plantpal/links"
    private val authChannelName = "plantpal/auth"
    private val reqCamera = 7001
    private val reqGallery = 7002
    private val reqNotifPerm = 7003
    private val reqCameraPerm = 7004
    private val reqGoogle = 7005
    private val maxDim = 1600
    private val jpegQuality = 85
    private val androidNotifChannelId = "plantpal_care"

    private var pendingMediaResult: MethodChannel.Result? = null
    private var pendingPermResult: MethodChannel.Result? = null
    private var pendingAuthResult: MethodChannel.Result? = null
    private var cameraFile: File? = null

    private var initialLink: String? = null
    private var linkChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        initialLink = intent?.dataString
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.dataString?.let { linkChannel?.invokeMethod("link", it) }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, mediaChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "camera" -> startCamera(result)
                "gallery" -> startGallery(result)
                else -> result.notImplemented()
            }
        }

        linkChannel = MethodChannel(messenger, linkChannelName).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitial" -> {
                        result.success(initialLink)
                        initialLink = null
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(messenger, authChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "signIn" -> googleSignIn(call.argument<String>("webClientId"), result)
                "signOut" -> {
                    try {
                        GoogleSignIn.getClient(
                            this,
                            GoogleSignInOptions.Builder(
                                GoogleSignInOptions.DEFAULT_SIGN_IN
                            ).build(),
                        ).signOut()
                    } catch (_: Exception) {
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, notifChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(notifPermissionStatus())
                "requestPermission" -> requestNotifPermission(result)
                "openSettings" -> {
                    openNotificationSettings()
                    result.success(null)
                }
                "show" -> {
                    showNotification(
                        call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt(),
                        call.argument<String>("title") ?: "PlantPal",
                        call.argument<String>("body") ?: "",
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── media ────────────────────────────────────────────────────────────────

    private fun startCamera(result: MethodChannel.Result) {
        if (pendingMediaResult != null) {
            result.error("busy", "Another capture is already in progress", null)
            return
        }
        pendingMediaResult = result
        // Some OEM camera apps refuse to launch unless the *calling* app holds
        // CAMERA, even though the FileProvider path technically doesn't need
        // it. Request it up front so the camera reliably opens with a preview.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.CAMERA
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.CAMERA), reqCameraPerm)
            return
        }
        launchCameraIntent()
    }

    private fun launchCameraIntent() {
        val result = pendingMediaResult ?: return
        try {
            val file = File.createTempFile("pp_capture_", ".jpg", cacheDir)
            cameraFile = file
            val uri: Uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, uri)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (intent.resolveActivity(packageManager) == null) {
                pendingMediaResult = null
                result.error("no_camera", "This device has no camera app", null)
                return
            }
            startActivityForResult(intent, reqCamera)
        } catch (e: Exception) {
            pendingMediaResult = null
            result.error("camera_failed", e.message, null)
        }
    }

    // ── google sign-in ──────────────────────────────────────────────────────

    private fun googleSignIn(webClientId: String?, result: MethodChannel.Result) {
        if (webClientId.isNullOrBlank()) {
            result.error("no_client_id", "Missing Google web client id", null)
            return
        }
        if (pendingAuthResult != null) {
            result.error("busy", "A sign-in is already in progress", null)
            return
        }
        try {
            val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestIdToken(webClientId)
                .requestEmail()
                .build()
            val client = GoogleSignIn.getClient(this, gso)
            // Sign out first so the account chooser always appears rather than
            // silently reusing a stale account.
            client.signOut().addOnCompleteListener {
                pendingAuthResult = result
                startActivityForResult(client.signInIntent, reqGoogle)
            }
        } catch (e: Exception) {
            result.error("signin_failed", e.message, null)
        }
    }

    private fun startGallery(result: MethodChannel.Result) {
        if (pendingMediaResult != null) {
            result.error("busy", "Another capture is already in progress", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                type = "image/*"
                addCategory(Intent.CATEGORY_OPENABLE)
            }
            pendingMediaResult = result
            startActivityForResult(Intent.createChooser(intent, "Select a photo"), reqGallery)
        } catch (e: Exception) {
            result.error("gallery_failed", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == reqGoogle) {
            val authResult = pendingAuthResult ?: return
            pendingAuthResult = null
            try {
                val account = GoogleSignIn.getSignedInAccountFromIntent(data)
                    .getResult(ApiException::class.java)
                val idToken = account?.idToken
                if (idToken.isNullOrBlank()) {
                    authResult.error("no_token", "Google returned no ID token", null)
                } else {
                    authResult.success(idToken)
                }
            } catch (e: ApiException) {
                // 12501 = user cancelled the chooser.
                if (e.statusCode == 12501) {
                    authResult.success(null)
                } else {
                    authResult.error("signin_failed", "Google sign-in failed (${e.statusCode})", null)
                }
            } catch (e: Exception) {
                authResult.error("signin_failed", e.message, null)
            }
            return
        }

        val result = pendingMediaResult ?: return
        pendingMediaResult = null
        try {
            when (requestCode) {
                reqCamera -> {
                    val file = cameraFile
                    if (resultCode == Activity.RESULT_OK && file != null && file.length() > 0) {
                        result.success(downscaleFromFile(file))
                    } else {
                        result.success(null)
                    }
                    file?.delete()
                    cameraFile = null
                }
                reqGallery -> {
                    val uri = data?.data
                    if (resultCode == Activity.RESULT_OK && uri != null) {
                        contentResolver.openInputStream(uri).use { input ->
                            result.success(downscaleFromStream(input))
                        }
                    } else {
                        result.success(null)
                    }
                }
            }
        } catch (e: Exception) {
            result.error("decode_failed", e.message ?: "Could not read the photo", null)
        }
    }

    private fun sampleSize(w: Int, h: Int): Int {
        var s = 1
        while (w / s > maxDim || h / s > maxDim) s *= 2
        return s
    }

    private fun encode(bitmap: Bitmap): ByteArray {
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, jpegQuality, out)
        return out.toByteArray()
    }

    private fun downscaleFromFile(file: File): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(file.absolutePath, bounds)
        val opts = BitmapFactory.Options().apply {
            inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight)
        }
        var bitmap = BitmapFactory.decodeFile(file.absolutePath, opts)
            ?: throw IllegalStateException("empty image")
        bitmap = applyExifRotation(bitmap, file.absolutePath)
        return encode(bitmap)
    }

    private fun downscaleFromStream(input: InputStream?): ByteArray {
        val bytes = input?.readBytes() ?: throw IllegalStateException("empty stream")
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        val opts = BitmapFactory.Options().apply {
            inSampleSize = sampleSize(bounds.outWidth, bounds.outHeight)
        }
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
            ?: throw IllegalStateException("undecodable image")
        return encode(bitmap)
    }

    private fun applyExifRotation(bitmap: Bitmap, path: String): Bitmap {
        return try {
            val exif = ExifInterface(path)
            val degrees = when (exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL
            )) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> return bitmap
            }
            val m = Matrix().apply { postRotate(degrees) }
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, m, true)
        } catch (_: Exception) {
            bitmap
        }
    }

    // ── notifications ────────────────────────────────────────────────────────

    private fun notifPermissionStatus(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return "granted"
        val granted = ContextCompat.checkSelfPermission(
            this, Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
        if (granted) return "granted"
        // rationale=true -> user dismissed once and we may ask again;
        // rationale=false -> never asked yet, or permanently denied.
        return if (shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS))
            "denied_can_retry" else "denied"
    }

    private fun requestNotifPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success("granted")
            return
        }
        if (ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success("granted")
            return
        }
        pendingPermResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), reqNotifPerm)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            reqNotifPerm -> {
                val result = pendingPermResult ?: return
                pendingPermResult = null
                val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
                result.success(if (granted) "granted" else notifPermissionStatus())
            }
            reqCameraPerm -> {
                val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
                if (granted) {
                    launchCameraIntent()
                } else {
                    val result = pendingMediaResult
                    pendingMediaResult = null
                    result?.error(
                        "camera_denied",
                        "Camera permission is needed to take a photo",
                        null,
                    )
                }
            }
        }
    }

    /** Opens this app's notification settings page so the user can flip the
     *  system toggle without hunting through Settings. */
    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(android.provider.Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(android.provider.Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
        }
        try {
            startActivity(intent)
        } catch (_: Exception) {
        }
    }

    private fun ensureNotifChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (mgr.getNotificationChannel(androidNotifChannelId) == null) {
                mgr.createNotificationChannel(
                    NotificationChannel(
                        androidNotifChannelId,
                        "Plant care reminders",
                        NotificationManager.IMPORTANCE_DEFAULT,
                    ).apply { description = "Watering, feeding and check-up reminders" }
                )
            }
        }
    }

    private fun showNotification(id: Int, title: String, body: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                this, Manifest.permission.POST_NOTIFICATIONS
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return // silently no-op if not permitted
        }
        ensureNotifChannel()
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            this, id, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, androidNotifChannelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pending)
            .build()
        androidx.core.app.NotificationManagerCompat.from(this).notify(id, notification)
    }
}
