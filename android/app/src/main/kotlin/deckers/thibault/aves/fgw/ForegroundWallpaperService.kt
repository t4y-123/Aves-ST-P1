package deckers.thibault.aves

import android.app.Service
import android.app.Notification
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.os.IBinder
import android.util.Log
import android.widget.Toast
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationManagerCompat
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.utils.startForegroundServiceCompat
import deckers.thibault.aves.utils.startService
import deckers.thibault.aves.utils.stopService
import deckers.thibault.aves.fgw.FgwSeviceNotificationHandler
import deckers.thibault.aves.fgw.FgwServiceActionHandler
import deckers.thibault.aves.fgw.FgwServiceFlutterHandler


class ForegroundWallpaperService : Service() {
    private lateinit var screenStateReceiver: BroadcastReceiver

    private var serviceContext = this

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(2, FgwSeviceNotificationHandler.createNotification(this))
        registerScreenStateReceiver()
        isRunning = true
        ForegroundWallpaperTileService.upTile(this,true)
        Log.i(LOG_TAG, "Foreground wallpaper service started")
        // Call the Dart start method via FgwServiceFlutterHandler
        FgwServiceFlutterHandler.callDartStartMethod(serviceContext)
    }

    // create update notification
    private fun createNotificationChannel() {
        val channel = NotificationChannelCompat.Builder(
            FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID,
            NotificationManagerCompat.IMPORTANCE_HIGH
        )
            .setName(applicationContext.getText(R.string.foreground_wallpaper_channel_name))
//            .setName("ForegroundWallpaper")
            .setShowBadge(false)
            .build()
        NotificationManagerCompat.from(applicationContext).createNotificationChannel(channel)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        FgwServiceActionHandler.handleStartCommand(serviceContext,intent,flags,startId)
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(LOG_TAG, "Clean foreground wallpaper flutterEngine")
        FgwServiceFlutterHandler.callDartStopMethod(serviceContext)
        // Unregister receiver for screen events
        unregisterScreenStateReceiver()
        isRunning = false
    }

    // Functionality of register and unregister for screen on, screen off, and screen unlock intents
    // when starting or stopping the service
    private fun registerScreenStateReceiver() {
        screenStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                FgwServiceActionHandler.handleStartCommand(context?:serviceContext,intent,0,0)
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

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ForegroundWallpaperService>()
        const val FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID = "foreground_wallpaper"

        var isRunning = false

        fun start(context: Context) {
            context.startService<ForegroundWallpaperService>()
        }

        fun startForeground(context: Context) {
            val intent = Intent(context, ForegroundWallpaperService::class.java)
            context.startForegroundServiceCompat(intent)
        }

        fun stop(context: Context) {
            context.stopService<ForegroundWallpaperService>()
        }
    }
}
