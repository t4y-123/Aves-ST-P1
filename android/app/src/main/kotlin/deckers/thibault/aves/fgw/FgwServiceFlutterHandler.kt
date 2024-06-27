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

object FgwServiceFlutterHandler {
    // for dart side code
    private val LOG_TAG = LogUtils.createTag<FgwServiceFlutterHandler>()
    private const val FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL =
        "deckers.thibault/aves/foreground_wallpaper_notification_service"
    private const val FOREGROUND_WALLPAPER_SERVICE_DART_ENTRYPOINT = "fgwNotificationService"

    private var flutterEngine: FlutterEngine? = null
    private var imageByteFetchJob: Job? = null
    private val defaultScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    private suspend fun initFlutterEngine(context: Context) {
        if (flutterEngine != null) return

        FlutterUtils.runOnUiThread {
            flutterEngine = FlutterEngine(context.applicationContext)
        }
        initChannels(context)

        flutterEngine!!.apply {
            if (!dartExecutor.isExecutingDart) {
                val appBundlePathOverride = FlutterInjector.instance().flutterLoader().findAppBundlePath()
                val entrypoint = DartExecutor.DartEntrypoint(appBundlePathOverride, FOREGROUND_WALLPAPER_SERVICE_DART_ENTRYPOINT)
                FlutterUtils.runOnUiThread {
                    dartExecutor.executeDartEntrypoint(entrypoint)
                }
            }
        }
    }

    private fun initChannels(context: Context) {
        val engine = flutterEngine
        engine ?: throw Exception("Flutter engine is not initialized")

        val messenger = engine.dartExecutor

        // dart -> platform -> dart
        // - need Context
        MethodChannel(messenger, DeviceHandler.CHANNEL).setMethodCallHandler(DeviceHandler(context))
        MethodChannel(messenger, MediaStoreHandler.CHANNEL).setMethodCallHandler(MediaStoreHandler(context))
        MethodChannel(messenger, MediaFetchBytesHandler.CHANNEL, AvesByteSendingMethodCodec.INSTANCE).setMethodCallHandler(MediaFetchBytesHandler(context))
        MethodChannel(messenger, MediaFetchObjectHandler.CHANNEL).setMethodCallHandler(MediaFetchObjectHandler(context))
        MethodChannel(messenger, StorageHandler.CHANNEL).setMethodCallHandler(StorageHandler(context))

        // result streaming: dart -> platform ->->-> dart
        // - need Context
        StreamsChannel(messenger, ImageByteStreamHandler.CHANNEL).setStreamHandlerFactory { args -> ImageByteStreamHandler(context, args) }
        StreamsChannel(messenger, MediaStoreStreamHandler.CHANNEL).setStreamHandlerFactory { args -> MediaStoreStreamHandler(context, args) }
    }

    private suspend fun getUpdateNotificationProps(
        context: Context,
    ): FieldMap? {
        Log.d(LOG_TAG, "start to getUpdateNotificationProps")
        initFlutterEngine(context)
        val messenger = flutterEngine!!.dartExecutor
        val channel = MethodChannel(messenger, FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL)
        try {
            val props = suspendCoroutine<Any?> { cont ->
                defaultScope.launch {
                    FlutterUtils.runOnUiThread {
                        channel?.invokeMethod("updateNotificationProp", null, object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                Log.d(LOG_TAG, " getUpdateNotificationProps result:$result")
                                cont.resume(result)
                            }

                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                cont.resumeWithException(Exception("$errorCode: $errorMessage\n$errorDetails"))
                            }

                            override fun notImplemented() {
                                cont.resumeWithException(Exception("not implemented"))
                            }
                        })
                    }
                }
            }
            @Suppress("unchecked_cast")
            return props as FieldMap?
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to getUpdateNotificationProps", e)
        }
        return null
    }

    fun nextWallpaper(context: Context) {
        defaultScope.launch {
            try {
                initFlutterEngine(context)
                val messenger = flutterEngine!!.dartExecutor
                val channel = MethodChannel(messenger, FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL)
                FlutterUtils.runOnUiThread {
                    channel.invokeMethod("nextWallpaper", null, object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            Log.d(LOG_TAG, "nextWallpaper success: $result")
                        }

                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            Log.e(LOG_TAG, "nextWallpaper error: $errorCode, $errorMessage, $errorDetails")
                        }

                        override fun notImplemented() {
                            Log.e(LOG_TAG, "nextWallpaper not implemented")
                        }
                    })
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Failed to invoke nextWallpaper", e)
            }
        }
    }

    private fun parseColorString(colorString: String?): Int? {
        if (colorString == null) return null

        // Example colorString format: "Color(0xff808080)"
        val regex = Regex("^Color\\(0x([0-9a-fA-F]+)\\)\$")
        val matchResult = regex.find(colorString) ?: return null

        return try {
            val hexColor = matchResult.groupValues[1]
            val alpha = hexColor.substring(0, 2).toInt(16) // Alpha component
            val red = hexColor.substring(2, 4).toInt(16) // Red component
            val green = hexColor.substring(4, 6).toInt(16) // Green component
            val blue = hexColor.substring(6, 8).toInt(16) // Blue component

            // Combine components into ARGB color format (alpha in highest byte)
            (alpha shl 24) or (red shl 16) or (green shl 8) or blue
        } catch (e: NumberFormatException) {
            e.printStackTrace()
            null
        }
    }

    fun updateNotificationFromDart(context: Context) {
        defaultScope.launch {
            try {
                val props = getUpdateNotificationProps(context)
                Log.d(LOG_TAG, "updateNotificationFromDart props: $props")

                // Update local values only if props are not null
                props?.let {
                    FgwSeviceNotificationHandler.guardLevel = it["guardLevel"] as? String ?: FgwSeviceNotificationHandler.guardLevel
                    FgwSeviceNotificationHandler.titleName = it["titleName"] as? String ?: FgwSeviceNotificationHandler.titleName
                    val colorString = it["color"] as? String
                    FgwSeviceNotificationHandler.color = parseColorString(colorString) ?: FgwSeviceNotificationHandler.color
                }

                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context) // Update notification with updated values
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Failed to get update notification props", e)
            }
        }
    }

}
