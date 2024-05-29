package deckers.thibault.aves


import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import android.widget.Toast;
import androidx.core.content.ContextCompat
import app.loup.streams_channel.StreamsChannel
import deckers.thibault.aves.channel.AvesByteSendingMethodCodec
import deckers.thibault.aves.channel.calls.*
import deckers.thibault.aves.channel.streams.ImageByteStreamHandler
import deckers.thibault.aves.channel.streams.MediaStoreStreamHandler
import deckers.thibault.aves.model.FieldMap
import deckers.thibault.aves.utils.FlutterUtils
import deckers.thibault.aves.utils.LogUtils
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.nio.ByteBuffer
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine
import kotlin.math.roundToInt
import io.flutter.plugin.common.MethodCall

class ForegroundWallpaperWidgetProvider : AppWidgetProvider() {
    private val defaultScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent) // Ensure that widget-related events are handled

        Log.i(LOG_TAG, "onReceive intent=$intent")
        val action = intent.action
        val serviceIntent = Intent(context, ForegroundWallpaperService::class.java)

        when (action) {
            ACTION_START_FOREGROUND -> {
                Log.i(LOG_TAG, "Starting ForegroundWallpaperService")
                if (!ForegroundWallpaperService.isRunning) {
                    serviceIntent.action = ACTION_START_FOREGROUND
                    ContextCompat.startForegroundService(context, serviceIntent)
                    Toast.makeText(context, "Start ForegroundWallpaper on BroadcastReceiver", Toast.LENGTH_SHORT).show()
                } else {
                    Toast.makeText(context, "ForegroundWallpaper is already running", Toast.LENGTH_SHORT).show()
                }
            }
            ACTION_STOP_FOREGROUND -> {
//                Log.i(LOG_TAG, "Stopping ForegroundWallpaperService")
//                context.stopService(serviceIntent)
//                Toast.makeText(context, "Stop ForegroundWallpaper on BroadcastReceiver", Toast.LENGTH_SHORT).show()
                Log.i(LOG_TAG, "Stopping ForegroundWallpaperService")
                serviceIntent.action = ACTION_STOP_FOREGROUND
                context.stopService(serviceIntent)
                Toast.makeText(context, "Stop ForegroundWallpaper on BroadcastReceiver", Toast.LENGTH_SHORT).show()
            }
        }
    }

    companion object {
        const val ACTION_START_FOREGROUND = "deckers.thibault.aves.ACTION_START_FOREGROUND_WALLPAPER"
        const val ACTION_STOP_FOREGROUND = "deckers.thibault.aves.ACTION_STOP_FOREGROUND_WALLPAPER"

        private val LOG_TAG = LogUtils.createTag<HomeWidgetProvider>()
        private const val FOREGROUND_WALLPAPER_DART_ENTRYPOINT = "foregroundWallpaper"
        private const val FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL = "deckers.thibault/aves/foreground_wallpaper_notification"
         // To communicate with flutter code.
        private var flutterEngine: FlutterEngine? = null
        private var imageByteFetchJob: Job? = null
        private var notificationChannel: MethodChannel? = null

        private suspend fun initFlutterEngine(context: Context) {
            if (flutterEngine != null) return

            FlutterUtils.runOnUiThread {
                flutterEngine = FlutterEngine(context.applicationContext)
            }
            initChannels(context)

            flutterEngine!!.apply {
                if (!dartExecutor.isExecutingDart) {
                    val appBundlePathOverride =
                        FlutterInjector.instance().flutterLoader().findAppBundlePath()
                    val entrypoint = DartExecutor.DartEntrypoint(
                        appBundlePathOverride,
                        FOREGROUND_WALLPAPER_DART_ENTRYPOINT
                    )
                    FlutterUtils.runOnUiThread {
                        dartExecutor.executeDartEntrypoint(entrypoint)
                    }
                }
            }
        }

        // communicate with flutter side code.
        private fun initChannels(context: Context) {
            val engine = flutterEngine
            engine ?: throw Exception("Flutter engine is not initialized")

            val messenger = engine.dartExecutor
            notificationChannel =
                MethodChannel(messenger, FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL).apply {
                    setMethodCallHandler { call, result -> onMethodCall(call, result) }
                }
        }

        private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            when (call.method) {
                "initialized" -> {
                    Log.d(LOG_TAG, "Foreground wallpaper channel is ready")
                    result.success(null)
                }

                "updateNotification" -> {
                    //                val title = call.argument<String>("title")
                    //                val message = call.argument<String>("message")
                    //                setForegroundAsync(createForegroundInfo(title, message))
                    result.success(null)
                }

                "stop" -> {

                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }// onMethodCall
    }
}

