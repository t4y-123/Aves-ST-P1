package deckers.thibault.aves.fgw

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

object FgwServiceActionHandler {
    private val LOG_TAG = LogUtils.createTag<FgwServiceActionHandler>()

    fun handleStartCommand(context: Context, intent: Intent?, flags: Int, startId: Int) {
        when (intent?.action) {
            FgwIntentAction.SWITCH_GROUP -> {
                FgwSeviceNotificationHandler.isLevelGroup = !FgwSeviceNotificationHandler.isLevelGroup
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.LEFT -> showToast(context, "Left arrow tapped")
            FgwIntentAction.RIGHT -> {
                showToast(context, "Right arrow tapped")
                FgwServiceFlutterHandler.nextWallpaper(context)  // Add this line
            }
            FgwIntentAction.DUPLICATE -> showToast(context, "Duplicate icon tapped")
            FgwIntentAction.STORES -> {
                showToast(context, "Reshuffle icon tapped")
                FgwServiceFlutterHandler.updateNotificationFromDart(context)
            }
            FgwIntentAction.DOWNWARD -> {
                FgwSeviceNotificationHandler.isChangingGuardLevel = true
                FgwSeviceNotificationHandler.tmpGuardLevel -= 1
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.UPWARD -> {
                FgwSeviceNotificationHandler.isChangingGuardLevel = true
                FgwSeviceNotificationHandler.tmpGuardLevel += 1
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.CANCEL_LEVEL_CHANGE -> {
                FgwSeviceNotificationHandler.tmpGuardLevel = FgwSeviceNotificationHandler.guardLevel.toInt()
                FgwSeviceNotificationHandler.isChangingGuardLevel = false
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.APPLY_LEVEL_CHANGE -> {
                FgwSeviceNotificationHandler.guardLevel = FgwSeviceNotificationHandler.tmpGuardLevel.toString()
                FgwSeviceNotificationHandler.isChangingGuardLevel = false
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.LOCK_UNLOCK -> {
                FgwSeviceNotificationHandler.canChangeLevel = !FgwSeviceNotificationHandler.canChangeLevel
                showToast(context,if (FgwSeviceNotificationHandler.canChangeLevel) "Locked" else "Unlocked")
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }

            Intent.ACTION_SCREEN_ON -> handleScreenOn(context)
            Intent.ACTION_SCREEN_OFF -> handleScreenOff(context)
            Intent.ACTION_USER_PRESENT -> handleUserPresent(context)
        }
    }

    private fun handleScreenOn(context:Context) {
        // Handle screen on event
        Log.i(LOG_TAG, "Screen ON")
        FgwServiceFlutterHandler.updateNotificationFromDart(context)
    }

    private fun handleScreenOff(context:Context) {
        // Handle screen off event
        Log.i(LOG_TAG, "Screen OFF")
        FgwServiceFlutterHandler.updateNotificationFromDart(context)
    }

    private fun handleUserPresent(context:Context) {
        // Handle user present (unlock) event
        Log.i(LOG_TAG, "User Present (Unlocked)")
        FgwServiceFlutterHandler.updateNotificationFromDart(context)
    }

    private fun showToast(context:Context, message: String) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
}
