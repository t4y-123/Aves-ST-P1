package deckers.thibault.aves.fgw

import android.content.Context
import android.content.res.Configuration
import android.util.Log
import androidx.core.app.NotificationManagerCompat
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
import kotlin.coroutines.suspendCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

object FgwServiceFlutterHandler {
    val LOG_TAG = LogUtils.createTag<FgwServiceFlutterHandler>()
    private const val FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL =
        "deckers.thibault/aves/foreground_wallpaper_notification_service"
    private const val FOREGROUND_WALLPAPER_SERVICE_DART_ENTRYPOINT = "fgwNotificationService"

    private var flutterEngine: FlutterEngine? = null
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
                val entrypoint =
                    DartExecutor.DartEntrypoint(appBundlePathOverride, FOREGROUND_WALLPAPER_SERVICE_DART_ENTRYPOINT)
                FlutterUtils.runOnUiThread {
                    dartExecutor.executeDartEntrypoint(entrypoint)
                }
            }
        }
    }

    private fun initChannels(context: Context) {
        val engine = flutterEngine ?: throw Exception("Flutter engine is not initialized")
        val messenger = engine.dartExecutor

        // dart -> platform -> dart
        // - need Context
        MethodChannel(messenger, DeviceHandler.CHANNEL).setMethodCallHandler(DeviceHandler(context))
        MethodChannel(messenger, MediaStoreHandler.CHANNEL).setMethodCallHandler(MediaStoreHandler(context))
        MethodChannel(
            messenger,
            MediaFetchBytesHandler.CHANNEL,
            AvesByteSendingMethodCodec.INSTANCE
        ).setMethodCallHandler(MediaFetchBytesHandler(context))
        MethodChannel(messenger, MediaFetchObjectHandler.CHANNEL).setMethodCallHandler(MediaFetchObjectHandler(context))
        MethodChannel(messenger, StorageHandler.CHANNEL).setMethodCallHandler(StorageHandler(context))

        // result streaming: dart -> platform ->->-> dart
        // - need Context
        StreamsChannel(
            messenger,
            ImageByteStreamHandler.CHANNEL
        ).setStreamHandlerFactory { args -> ImageByteStreamHandler(context, args) }
        StreamsChannel(
            messenger,
            MediaStoreStreamHandler.CHANNEL
        ).setStreamHandlerFactory { args -> MediaStoreStreamHandler(context, args) }
    }

    private suspend inline fun <reified T> invokeFlutterMethod(
        context: Context,
        channelName: String,
        methodName: String,
        arguments: Any? = null,
        crossinline onSuccess: (result: T?) -> Unit = {},
        crossinline onError: (Exception) -> Unit = {}
    ) {
        try {
            initFlutterEngine(context)
            val messenger = flutterEngine!!.dartExecutor
            val channel = MethodChannel(messenger, channelName)
            FlutterUtils.runOnUiThread {
                channel.invokeMethod(methodName, arguments, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        onSuccess(result as? T)
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        onError(Exception("$errorCode: $errorMessage\n$errorDetails"))
                    }

                    override fun notImplemented() {
                        onError(Exception("not implemented"))
                    }
                })
            }
        } catch (e: Exception) {
            onError(e)
        }
    }

    fun callDartStartMethod(context: Context) {
        Log.i(LOG_TAG, "callDartStartMethod:start")
        defaultScope.launch{
            suspendCoroutine<Any?> { continuation ->
                runBlocking {
                    Log.d(LOG_TAG, "callDartStartMethod invokeFlutterMethod:start")
                    invokeFlutterMethod<Any>(context, FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL, "start",
                        onSuccess = { result -> Log.d(LOG_TAG, "Dart start method invoked successfully: $result") },
                        onError = { e -> Log.e(LOG_TAG, "Failed to invoke Dart start method", e) }
                    )
                }
                Log.d(LOG_TAG, "callDartStartMethod:runBlocking end")
            }
        }
        Log.i(LOG_TAG, "callDartStartMethod:end")
    }

    fun callDartStopMethod(context: Context) {
        Log.i(LOG_TAG, "callDartStopMethod:start")
        defaultScope.launch{
            suspendCoroutine<Any?> { continuation ->
                runBlocking {
                    Log.d(LOG_TAG, "callDartStopMethod invokeFlutterMethod:stop")
                    invokeFlutterMethod<Any>(context, FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL, "stop",
                        onSuccess = { result -> Log.d(LOG_TAG, "Dart stop method invoked successfully: $result") },
                        onError = { e -> Log.e(LOG_TAG, "Failed to invoke Dart stop method", e) }
                    )
                }
                Log.d(LOG_TAG, "callDartStopMethod:runBlocking end")
            }
        }
        Log.i(LOG_TAG, "callDartStopMethod:end")
    }


    fun nextWallpaper(context: Context) {
        runBlocking {
            invokeFlutterMethod<Any>(context, FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL, "nextWallpaper",
                arguments = hashMapOf(
                    "updateType" to "home",  // Replace with actual data
                    "widgetId" to 0,
                ),
                onSuccess = { result -> Log.d(LOG_TAG, "nextWallpaper success: $result") },
                onError = { e -> Log.e(LOG_TAG, "Failed to invoke nextWallpaper", e) }
            )
        }
    }

    private suspend fun getUpdateNotificationProps(context: Context): FieldMap? {
        Log.d(LOG_TAG, "start to getUpdateNotificationProps")
        return try {
            suspendCoroutine<FieldMap?> { continuation ->
                defaultScope.launch{
                    invokeFlutterMethod<FieldMap>(context,
                        FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL,
                        "updateNotificationProp",
                        onSuccess = { result -> continuation.resume(result) },
                        onError = { e -> continuation.resumeWithException(e) }
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to getUpdateNotificationProps", e)
            null
        }
    }

    fun updateNotificationFromDart(context: Context) {
        defaultScope.launch {
            try {
                val props = getUpdateNotificationProps(context)
                Log.d(LOG_TAG, "updateNotificationFromDart props: $props")

                props?.let {
                    FgwSeviceNotificationHandler.guardLevel =
                        it["guardLevel"] as? String ?: FgwSeviceNotificationHandler.guardLevel
                    FgwSeviceNotificationHandler.titleName =
                        it["titleName"] as? String ?: FgwSeviceNotificationHandler.titleName
                    val colorString = it["color"] as? String
                    FgwSeviceNotificationHandler.color =
                        parseColorString(colorString) ?: FgwSeviceNotificationHandler.color
                }

                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Failed to get update notification props", e)
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
}
