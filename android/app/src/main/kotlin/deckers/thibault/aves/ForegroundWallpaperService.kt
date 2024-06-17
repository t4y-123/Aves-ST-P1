package deckers.thibault.aves

import android.app.Service
import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.os.IBinder
import android.content.pm.ServiceInfo
import android.widget.Toast;
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.ForegroundInfo
import kotlinx.coroutines.*
import deckers.thibault.aves.utils.FlutterUtils
import deckers.thibault.aves.utils.LogUtils
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.runBlocking
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine


class ForegroundWallpaperService : Service() {

    private var isGroup1 = true
    private lateinit var screenStateReceiver: BroadcastReceiver

    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()
        startForeground(2, createNotification())
        updateNotification()
        isRunning = true
        Log.i(LOG_TAG, "Foreground wallpaper service started")
        // Register receiver for screen events
        registerScreenStateReceiver()

    }

    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java), 0
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
            .setContentTitle("Foreground Service")
            .setContentText("Running...")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setTicker("Ticker text")
            .build()
    }

    // Functionality of register and unregister for screen on, screen off, and screen unlock intents
    // when starting or stopping the service
    private fun registerScreenStateReceiver() {
        screenStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON -> handleScreenOn()
                    Intent.ACTION_SCREEN_OFF -> handleScreenOff()
                    Intent.ACTION_USER_PRESENT -> handleUserPresent()
                    Intent.ACTION_TIME_CHANGED -> handleUserPresent()
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenStateReceiver, filter)
    }

    private fun unregisterScreenStateReceiver() {
        try {
            unregisterReceiver(screenStateReceiver)
        } catch (e: IllegalArgumentException) {
            Log.e(LOG_TAG, "Screen state receiver not registered", e)
        }
    }

    // create update notification
    private fun createNotificationChannel() {
        val channel = NotificationChannelCompat.Builder(NOTIFICATION_CHANNEL, NotificationManagerCompat.IMPORTANCE_LOW)
            //.setName(applicationContext.getText(R.string.analysis_channel_name))
            .setName("ForegroundWallpaper")
            .setShowBadge(false)
            .build()
        NotificationManagerCompat.from(applicationContext).createNotificationChannel(channel)
    }

    private fun updateNotification() {
        val foregroundInfo = createForegroundInfo()
        val notificationManager = NotificationManagerCompat.from(applicationContext)
        notificationManager.notify(NOTIFICATION_ID, foregroundInfo.notification)
    }

    private fun createForegroundInfo(title: String? = null, message: String? = null): ForegroundInfo {
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val openAppIntent = Intent(applicationContext, MainActivity::class.java).let {
            PendingIntent.getActivity(applicationContext, MainActivity.OPEN_FROM_ANALYSIS_SERVICE, it, pendingIntentFlags)
        }

        val switchPendingIntent = createPendingIntent(ACTION_SWITCH_GROUP)

        val group1Actions = listOf(
            NotificationCompat.Action.Builder(R.drawable.baseline_pages_24, "Switch", switchPendingIntent).build(),
            createSimpleAction(R.drawable.baseline_pages_24, "Left", ACTION_LEFT),
            createSimpleAction(R.drawable.baseline_pages_24, "Right", ACTION_RIGHT),
            createSimpleAction(R.drawable.baseline_pages_24, "Duplicate", ACTION_DUPLICATE),
            createSimpleAction(R.drawable.baseline_pages_24, "Reshuffle", ACTION_RESHUFFLE)
        )

        val group2Actions = listOf(
            NotificationCompat.Action.Builder(R.drawable.baseline_pages_24, "Switch", switchPendingIntent).build(),
            createSimpleAction(R.drawable.ic_outline_stop_24, "Downward", ACTION_DOWNWARD),
            createSimpleAction(R.drawable.ic_outline_stop_24, "Upward", ACTION_UPWARD),
            createSimpleAction(R.drawable.ic_outline_stop_24, "Option 4", "ACTION_OPTION_4"),
            createSimpleAction(R.drawable.ic_outline_stop_24, "Option 5", "ACTION_OPTION_5")
        )

        val actionsToShow = if (isGroup1) group1Actions else group2Actions

        val contentTitle = title ?: "Foreground Wallpaper"
        val notification = NotificationCompat.Builder(applicationContext, NOTIFICATION_CHANNEL)
            .setContentTitle(contentTitle)
            .setTicker(contentTitle)
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setContentIntent(openAppIntent)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .also { builder ->
                actionsToShow.forEach { action ->
                    builder.addAction(action)
                }
            }
            .build()

        return if (Build.VERSION.SDK_INT >= 34) {
            // from Android 14 (API 34), foreground service type is mandatory
            // despite the sample code omitting it at:
            // https://developer.android.com/guide/background/persistent/how-to/long-running
            // TODO TLAD [Android 15 (API 35)] use `FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK`
            //  for it use to 'display' the wallpaper in periodic time
            val type = ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            ForegroundInfo(NOTIFICATION_ID, notification, type)
        } else {
            ForegroundInfo(NOTIFICATION_ID, notification)
        }
    }

    private fun createSimpleAction(icon: Int, title: String, action: String): NotificationCompat.Action {
        val intent = Intent(applicationContext, ForegroundWallpaperService::class.java).apply {
            this.action = action
        }
        val pendingIntent = PendingIntent.getService(applicationContext, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
        return NotificationCompat.Action.Builder(icon, title, pendingIntent).build()
    }

    private fun createPendingIntent(action: String): PendingIntent {
        val intent = Intent(applicationContext, ForegroundWallpaperService::class.java).apply {
            this.action = action
        }
        return PendingIntent.getService(applicationContext, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SWITCH_GROUP -> {
                isGroup1 = !isGroup1
                updateNotification()
            }
            ForegroundWallpaperWidgetProvider.ACTION_STOP_FOREGROUND -> {
                stopForeground(true)
                stopSelf()
            }
            ACTION_LEFT -> showToast("Left arrow tapped")
            ACTION_RIGHT -> showToast("Right arrow tapped")
            ACTION_DUPLICATE -> showToast("Duplicate icon tapped")
            ACTION_RESHUFFLE -> showToast("Reshuffle icon tapped")
            ACTION_DOWNWARD -> showToast("Downward arrow tapped")
            ACTION_UPWARD -> showToast("Upward arrow tapped")
            Intent.ACTION_SCREEN_ON -> handleScreenOn()
            Intent.ACTION_SCREEN_OFF -> handleScreenOff()
            Intent.ACTION_USER_PRESENT -> handleUserPresent()
        }
        return START_STICKY
    }

    private fun handleScreenOn() {
        // Handle screen on event
        Log.i(LOG_TAG, "Screen ON")
    }

    private fun handleScreenOff() {
        // Handle screen off event
        Log.i(LOG_TAG, "Screen OFF")
    }

    private fun handleUserPresent() {
        // Handle user present (unlock) event
        Log.i(LOG_TAG, "User Present (Unlocked)")
    }

    private fun handleStartService() {
        // Handle starting the service
        Log.i(LOG_TAG, "Service started")
    }

    private fun showToast(message: String) {
        Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show()
    }

    // create and update notification end


    override fun onDestroy() {
        super.onDestroy()
        Log.i(LOG_TAG, "Clean foreground wallpaper flutterEngine")
        // Unregister receiver for screen events
        unregisterScreenStateReceiver()
        isRunning = false
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ForegroundWallpaperService>()
        const val NOTIFICATION_CHANNEL = "foreground_wallpaper"
        const val NOTIFICATION_ID = 2

        const val KEY_ENTRY_IDS = "entry_ids"
        const val KEY_FORCE = "force"
        const val KEY_PROGRESS_TOTAL = "progress_total"
        const val KEY_PROGRESS_OFFSET = "progress_offset"

        const val ACTION_SWITCH_GROUP = "ACTION_SWITCH_GROUP"
        const val ACTION_LEFT = "ACTION_LEFT"
        const val ACTION_RIGHT = "ACTION_RIGHT"
        const val ACTION_DUPLICATE = "ACTION_DUPLICATE"
        const val ACTION_RESHUFFLE = "ACTION_RESHUFFLE"
        const val ACTION_DOWNWARD = "ACTION_DOWNWARD"
        const val ACTION_UPWARD = "ACTION_UPWARD"

        var isRunning = false
    }
}
