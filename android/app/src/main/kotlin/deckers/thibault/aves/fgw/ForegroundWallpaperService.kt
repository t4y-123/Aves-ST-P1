package deckers.thibault.aves

import android.annotation.SuppressLint
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
import androidx.core.content.ContextCompat
import app.loup.streams_channel.StreamsChannel
import kotlinx.coroutines.*
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.utils.startForegroundServiceCompat
import deckers.thibault.aves.utils.startService
import deckers.thibault.aves.utils.stopService
import deckers.thibault.aves.utils.servicePendingIntent
import deckers.thibault.aves.utils.activityPendingIntent
import deckers.thibault.aves.fgw.*
import deckers.thibault.aves.ForegroundWallpaperService
import deckers.thibault.aves.channel.calls.DeviceHandler
import deckers.thibault.aves.channel.calls.MediaStoreHandler
import deckers.thibault.aves.channel.calls.MediaFetchObjectHandler
import deckers.thibault.aves.channel.calls.MediaFetchBytesHandler
import deckers.thibault.aves.channel.calls.StorageHandler
import deckers.thibault.aves.channel.streams.ImageByteStreamHandler
import deckers.thibault.aves.channel.streams.MediaStoreStreamHandler
import deckers.thibault.aves.channel.AvesByteSendingMethodCodec
import deckers.thibault.aves.model.FieldMap
import deckers.thibault.aves.utils.FlutterUtils
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

import deckers.thibault.aves.channel.calls.MetadataFetchHandler
import deckers.thibault.aves.channel.calls.GeocodingHandler


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
