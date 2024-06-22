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
import android.widget.RemoteViews
import android.app.KeyguardManager
import android.graphics.Color
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

    private lateinit var screenStateReceiver: BroadcastReceiver

    override fun onCreate() {
        super.onCreate()

        createNotificationChannel()
        startForeground(2, createNotification())
        registerScreenStateReceiver()
        isRunning = true
        updateNotification()
        startForegroundWallpaperTileService()
        Log.i(LOG_TAG, "Foreground wallpaper service started")
    }

    private fun startForegroundWallpaperTileService() {
        val intent = Intent(this, ForegroundWallpaperTileService::class.java)
        intent.action = ForegroundWallpaperTileService.ACTION_START_FGW_TILE_SERIVCE
        startService(intent)
        Log.i(LOG_TAG, "Foreground wallpaper tile service start intent sent")
    }

    private fun createNotification(): Notification {
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val pendingIntent = Intent(applicationContext, MainActivity::class.java).let {
            PendingIntent.getActivity(applicationContext, MainActivity.OPEN_FROM_ANALYSIS_SERVICE, it, pendingIntentFlags)
        }

        val builder = NotificationCompat.Builder(this, FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setTicker("Ticker text")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)
        builder.setCustomContentView(getNormalContentView())
        builder.setCustomBigContentView(getBigContentView())

        return builder.build()
    }

    private fun updateNotification() {
        val notification = createNotification()
        val notificationManager = NotificationManagerCompat.from(applicationContext)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun getNormalContentView(): RemoteViews {
        val remoteViews = RemoteViews(packageName, R.layout.fgw_notification_normal)

        val statusText: String
        val statusColor: Int

        if (isLocked) {
            statusText = "3"
            statusColor = android.R.color.holo_blue_dark
        } else {
            if (isGroup1) {
                statusText = "1"
                statusColor = android.R.color.darker_gray
            } else {
                statusText = "2"
                statusColor = android.R.color.holo_purple
            }
        }

        remoteViews.setTextViewText(R.id.tv_status, statusText)
        remoteViews.setInt(R.id.tv_status, "setBackgroundColor", resources.getColor(statusColor, null))


        if(isScreenLocked()){
            remoteViews.setImageViewResource(R.id.iv_normal_layout_button_01, R.drawable.baseline_arrow_downward_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_normal_layout_button_01, createPendingIntent(ACTION_DOWNWARD))

            remoteViews.setImageViewResource(R.id.iv_normal_layout_button_02, R.drawable.baseline_arrow_upward_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_normal_layout_button_02, createPendingIntent(ACTION_UPWARD))

            if(isLocked){
                remoteViews.setImageViewResource(R.id.iv_normal_layout_button_03, R.drawable.baseline_lock_24)
            }else{
                remoteViews.setImageViewResource(R.id.iv_normal_layout_button_03, R.drawable.baseline_lock_open_24)
            }
            remoteViews.setOnClickPendingIntent(R.id.iv_normal_layout_button_03, createPendingIntent(ACTION_LOCK_UNLOCK))

            remoteViews.setImageViewResource(R.id.iv_normal_layout_button_04, R.drawable.baseline_check_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_normal_layout_button_04, createPendingIntent(ACTION_APPLY_LEVEL_CHANGE))

        }else{
            remoteViews.setImageViewResource(R.id.iv_normal_layout_button_01, R.drawable.baseline_navigate_before_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_normal_layout_button_01, createPendingIntent(ACTION_LEFT))

            remoteViews.setImageViewResource(R.id.iv_normal_layout_button_02, R.drawable.baseline_navigate_next_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_normal_layout_button_02, createPendingIntent(ACTION_RIGHT))

            remoteViews.setImageViewResource(R.id.iv_normal_layout_button_03, R.drawable.baseline_add_photo_alternate_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_normal_layout_button_03, createPendingIntent(ACTION_DUPLICATE))

            remoteViews.setImageViewResource(R.id.iv_normal_layout_button_04, R.drawable.baseline_shuffle_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_normal_layout_button_04, createPendingIntent(ACTION_RESHUFFLE))
        }

        return remoteViews
    }

    private fun getBigContentView(): RemoteViews {
        val remoteViews = RemoteViews(packageName, R.layout.fgw_notification_big)

        val statusText: String
        val statusColor: Int

        if (isLocked) {
            statusText = "3"
            statusColor = android.R.color.holo_blue_dark
        } else {
            if (isGroup1) {
                statusText = "1"
                statusColor = android.R.color.darker_gray
            } else {
                statusText = "2"
                statusColor = android.R.color.holo_purple
            }
        }

        remoteViews.setTextViewText(R.id.tv_status, statusText)
        remoteViews.setInt(R.id.tv_status, "setBackgroundColor", resources.getColor(statusColor, null))

        remoteViews.setImageViewResource(R.id.iv_big_layout_button_01, R.drawable.baseline_menu_open_24)
        remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_01, createPendingIntent(ACTION_SWITCH_GROUP))

        if (isGroup1) {
            remoteViews.setImageViewResource(R.id.iv_big_layout_button_02, R.drawable.baseline_navigate_before_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_02, createPendingIntent(ACTION_LEFT))


            remoteViews.setImageViewResource(R.id.iv_big_layout_button_03, R.drawable.baseline_navigate_next_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_03, createPendingIntent(ACTION_RIGHT))

            remoteViews.setImageViewResource(R.id.iv_big_layout_button_04, R.drawable.baseline_add_photo_alternate_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_04, createPendingIntent(ACTION_DUPLICATE))

            remoteViews.setImageViewResource(R.id.iv_big_layout_button_05, R.drawable.baseline_shuffle_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_05, createPendingIntent(ACTION_RESHUFFLE))
        } else {
            remoteViews.setImageViewResource(R.id.iv_big_layout_button_02, R.drawable.baseline_arrow_downward_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_02, createPendingIntent(ACTION_DOWNWARD))

            remoteViews.setImageViewResource(R.id.iv_big_layout_button_03, R.drawable.baseline_arrow_upward_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_03, createPendingIntent(ACTION_UPWARD))

            if(isLocked){
                remoteViews.setImageViewResource(R.id.iv_big_layout_button_04, R.drawable.baseline_lock_24)
            }else{
                remoteViews.setImageViewResource(R.id.iv_big_layout_button_04, R.drawable.baseline_lock_open_24)
            }
            remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_04, createPendingIntent(ACTION_LOCK_UNLOCK))

            remoteViews.setImageViewResource(R.id.iv_big_layout_button_05, R.drawable.baseline_check_24)
            remoteViews.setOnClickPendingIntent(R.id.iv_big_layout_button_05, createPendingIntent(ACTION_APPLY_LEVEL_CHANGE))
        }

        return remoteViews
    }


    // create update notification
    private fun createNotificationChannel() {
        val channel = NotificationChannelCompat.Builder(FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_HIGH)
            //.setName(applicationContext.getText(R.string.analysis_channel_name))
            .setName("ForegroundWallpaper")
            .setShowBadge(false)
            .build()
        NotificationManagerCompat.from(applicationContext).createNotificationChannel(channel)
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
            ACTION_APPLY_LEVEL_CHANGE ->showToast("APPLY LEVEL CHANGE")
            ACTION_LOCK_UNLOCK -> {
                isLocked = !isLocked
                showToast(if (isLocked) "Locked" else "Unlocked")
                updateNotification()
            }
            Intent.ACTION_SCREEN_ON -> handleScreenOn()
            Intent.ACTION_SCREEN_OFF -> handleScreenOff()
            Intent.ACTION_USER_PRESENT -> handleUserPresent()
        }
        return START_STICKY
    }

    private fun handleScreenOn() {
        // Handle screen on event
        Log.i(LOG_TAG, "Screen ON")
        updateNotification()
    }

    private fun handleScreenOff() {
        // Handle screen off event
        Log.i(LOG_TAG, "Screen OFF")
        updateNotification()
    }

    private fun handleUserPresent() {
        // Handle user present (unlock) event
        Log.i(LOG_TAG, "User Present (Unlocked)")
        updateNotification()
    }

    private fun handleStartService() {
        // Handle starting the service
        Log.i(LOG_TAG, "Service started")
        updateNotification()
    }



    // create and update notification end
    private fun isScreenLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(LOG_TAG, "Clean foreground wallpaper flutterEngine")
        // Unregister receiver for screen events
        unregisterScreenStateReceiver()
        isRunning = false
        Log.i(LOG_TAG, "On ForegroundWallpaperService")
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

    private fun showToast(message: String) {
        Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show()
    }
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ForegroundWallpaperService>()
        const val FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID = "foreground_wallpaper"
        const val NOTIFICATION_ID = 2
        const val ACTION_SERVICE_STATE_CHANGED = "ACTION_SERVICE_STATE_CHANGED"

        const val ACTION_SWITCH_GROUP = "ACTION_SWITCH_GROUP"
        const val ACTION_LEFT = "ACTION_LEFT"
        const val ACTION_RIGHT = "ACTION_RIGHT"
        const val ACTION_DUPLICATE = "ACTION_DUPLICATE"
        const val ACTION_RESHUFFLE = "ACTION_RESHUFFLE"
        const val ACTION_DOWNWARD = "ACTION_DOWNWARD"
        const val ACTION_UPWARD = "ACTION_UPWARD"
        const val ACTION_LOCK_UNLOCK = "ACTION_LOCK_UNLOCK"
        const val ACTION_APPLY_LEVEL_CHANGE = "ACTION_APPLY_LEVEL_CHANGE"

        var isGroup1 = true
        var isLocked = false
        var isRunning = false
    }
}
