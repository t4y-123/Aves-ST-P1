package deckers.thibault.aves.fgw

import android.content.Context
import android.content.res.Configuration
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import android.widget.Toast
import app.loup.streams_channel.StreamsChannel
import deckers.thibault.aves.channel.AvesByteSendingMethodCodec
import deckers.thibault.aves.channel.calls.*
import deckers.thibault.aves.channel.streams.ImageByteStreamHandler
import deckers.thibault.aves.channel.streams.MediaStoreStreamHandler
import deckers.thibault.aves.model.FieldMap
import deckers.thibault.aves.utils.FlutterUtils
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.fgw.*
import deckers.thibault.aves.R
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import kotlinx.coroutines.*
import kotlin.coroutines.suspendCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException


object FgwServiceFlutterHandler {
    val LOG_TAG = LogUtils.createTag<FgwServiceFlutterHandler>()
    private const val FGWN_SERVICE_OP_CHANNEL =
        "deckers.thibault/aves/fgw_service_notification_op"
    private const val FGWN_SERVICE_SYNC_CHANNEL =
        "deckers.thibault/aves/fgw_service_notification_sync"
    private const val FOREGROUND_WALLPAPER_SERVICE_DART_ENTRYPOINT = "fgwNotificationService"

    private var flutterEngine: FlutterEngine? = null
    private val defaultScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    var curUpdateType: String = FgwConstant.CUR_TYPE_HOME
    var curWidgetId: Int = FgwConstant.NOT_WIDGET_ID
    var curGuardLevel: Int = -1
    var entryFilename = ""
    var activeLevelsList: List<PrivacyGuardLevelRow> = listOf()
    var scheduleList: List<WallpaperScheduleRow> = listOf()

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

    fun initChannels(context: Context) {
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

        // sync data from dart side.
        MethodChannel(
            messenger,
            FGWN_SERVICE_SYNC_CHANNEL
        ).setMethodCallHandler { call, result ->
            Log.i(LOG_TAG, "${FGWN_SERVICE_SYNC_CHANNEL} setMethodCallHandler: ${call}")
            when (call.method) {
                "syncDataToKotlin" ->
                    handleSyncFromDartToNative(context,call, result)
                "showToast" ->  {
                    val message = call.argument<String>("message")
                    if (message != null) {
                        showToast(context,message)
                        result.success(null)
                    } else {
                        result.error("ERROR", "Message is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
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

    private fun handleSyncFromDartToNative(context: Context,call: MethodCall, result: MethodChannel.Result) {
        Log.d(LOG_TAG, "handleSyncFromDartToNative:start $call")
        Log.d(LOG_TAG, "handleSyncFromDartToNative:start ${call.arguments}")
        defaultScope.launch {
            // Current guard level
            val tmpCurGuardLevel = call.argument<String>(FgwConstant.CUR_LEVEL)
            Log.d(LOG_TAG, "handleSyncFromDartToNative:tmpCurGuardLevel ${tmpCurGuardLevel}")

            // Active levels
            val activeLevelsString = call.argument<String>(FgwConstant.ACTIVE_LEVELS)
            Log.d(LOG_TAG, "handleSyncFromDartToNative:activeLevelsString ${activeLevelsString}")
            if (tmpCurGuardLevel != null && activeLevelsString != null) {
                curGuardLevel = tmpCurGuardLevel.toInt()
                FgwSeviceNotificationHandler.guardLevel = curGuardLevel
                activeLevelsList = parseActiveLevelsString(activeLevelsString)
            }

            // Current entry file name
            val tmpEntryFileName = call.argument<String>(FgwConstant.CUR_ENTRY_NAME)
            Log.d(LOG_TAG, "handleSyncFromDartToNative:tmpEntryFileName ${tmpEntryFileName}")
            if (tmpEntryFileName != null) {
                entryFilename = tmpEntryFileName
            }

            // Schedules
            val schedulesString = call.argument<String>(FgwConstant.SCHEDULES)
            Log.d(LOG_TAG, "handleSyncFromDartToNative:schedulesString $schedulesString")
            if (schedulesString != null) {
                scheduleList =  parseSchedulesString(schedulesString)
                WallpaperScheduleHelper.handleSchedules(context,scheduleList)
            }

            Log.d(LOG_TAG, "handleSyncFromDartToNative:curGuardLevel $curGuardLevel")
            Log.d(LOG_TAG, "handleSyncFromDartToNative:activeLevelsList $activeLevelsList")
            Log.d(LOG_TAG, "handleSyncFromDartToNative:entryFilename $entryFilename")
            Log.d(LOG_TAG, "handleSyncFromDartToNative:scheduleList $scheduleList")

            FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            result.success(true)
        }
    }

    private fun parseActiveLevelsString(activeLevelsString: String): List<PrivacyGuardLevelRow> {
        return activeLevelsString.removePrefix("[").removeSuffix("]")
            .split("), ")
            .map { item ->
                val parts = item.removePrefix("PrivacyGuardLevelRow(").removeSuffix(")").split(", ")
                val id = parts[0].toInt()
                val level = parts[1].toInt()
                val name = parts[2]
                val color = parseColorString(parts[3]) ?: 0
                PrivacyGuardLevelRow(id, level, name, color)
            }
    }

    private fun parseColorString(colorString: String?): Int? {
        if (colorString == null) return null

        // Updated regex to match both "Color(0xff112233)" and "0xff112233"
        val regex = Regex("^(?:Color\\()?(0x[0-9a-fA-F]{8})\\)?\$")
        val matchResult = regex.find(colorString) ?: return null

        return try {
            val hexColor = matchResult.groupValues[1]
            val alpha = hexColor.substring(2, 4).toInt(16) // Alpha component
            val red = hexColor.substring(4, 6).toInt(16) // Red component
            val green = hexColor.substring(6, 8).toInt(16) // Green component
            val blue = hexColor.substring(8, 10).toInt(16) // Blue component

            // Combine components into ARGB color format (alpha in highest byte)
            (alpha shl 24) or (red shl 16) or (green shl 8) or blue
        } catch (e: NumberFormatException) {
            e.printStackTrace()
            null
        }
    }

    private fun parseSchedulesString(schedulesString: String): List<WallpaperScheduleRow> {
        return schedulesString.removePrefix("[").removeSuffix("]")
            .split("), ")
            .map { item ->
                val parts = item.removePrefix("WallpaperScheduleRow(").removeSuffix(")").split(", ")
                val id = parts[0].toInt()
                val order = parts[1].toInt()
                val label = parts[2]
                val guardLevelId = parts[3].toInt()
                val scheduleId = parts[4].toInt()
                val updateType = parts[5]
                val widgetId = parts[6].toInt()
                val displayType = parts[7]
                val interval = parts[8].toInt()
                val isActive = parts[9].toBoolean()
                WallpaperScheduleRow(
                    id,
                    order,
                    label,
                    guardLevelId,
                    scheduleId,
                    updateType,
                    widgetId,
                    displayType,
                    interval,
                    isActive
                )
            }
    }

    fun callDartNoArgsMethod(context: Context, opString: String) {
        Log.i(LOG_TAG, "callDartNoArgsMethod:start")
        defaultScope.launch {
            Log.d(LOG_TAG, " callDartNoArgsMethod $opString")
            invokeFlutterMethod<Any>(context, FGWN_SERVICE_OP_CHANNEL, opString,
                onSuccess = { result -> Log.i(LOG_TAG, "Dart [$opString] method invoked successfully: $result") },
                onError = { e -> Log.e(LOG_TAG, "Failed to invoke Dart method [$opString]", e) }
            )
        }
        Log.d(LOG_TAG, "callDartNoArgsMethod [$opString]:end")
    }

    fun handleWallpaper(context: Context, opString: String) {
        Log.d(LOG_TAG, "handleWallpaper: opString=$opString, updateType=$curUpdateType, widgetId=$curWidgetId")
        runBlocking {
            invokeFlutterMethod<Any>(context, FGWN_SERVICE_OP_CHANNEL, opString,
                arguments = hashMapOf(
                    "updateType" to curUpdateType,
                    "widgetId" to curWidgetId,
                ),
                onSuccess = { result -> Log.d(LOG_TAG, "$opString success: $result") },
                onError = { e -> Log.e(LOG_TAG, "Failed to invoke $opString", e) }
            )
        }
    }

    fun changeGuardLevel(context: Context, newGuardLevel:Int) {
        val opString = FgwConstant.CHANGE_GUARD_LEVEL
        Log.d(LOG_TAG, "changeGuardLevel [$context]:RUN")
        runBlocking {
            invokeFlutterMethod<Any>(context, FGWN_SERVICE_OP_CHANNEL,opString ,
                arguments = hashMapOf(
                    "newGuardLevel" to newGuardLevel,
                ),
                onSuccess = { result -> Log.d(LOG_TAG, "$opString success: $result") },
                onError = { e -> Log.e(LOG_TAG, "Failed to invoke $opString", e) }
            )
        }
    }

    private fun showToast(context:Context, message: String) {
        Log.i(LOG_TAG, "FgwServiceActionHandler $context : $message")
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
}
