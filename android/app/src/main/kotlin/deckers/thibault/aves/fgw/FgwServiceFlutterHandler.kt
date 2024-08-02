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
import org.json.JSONArray
import org.json.JSONObject

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

    private fun handleSyncFromDartToNative(context: Context, call: MethodCall, result: MethodChannel.Result) {
        Log.d(LOG_TAG, "handleSyncFromDartToNative:start $call")
        Log.d(LOG_TAG, "handleSyncFromDartToNative:start call.arguments ${call.arguments}")
        defaultScope.launch {
            try {
                // Current guard level
                Log.d(LOG_TAG, "handleSyncFromDartToNative:start deal tmpCurGuardLevel\n")
                val tmpCurGuardLevel = call.argument<String>(FgwConstant.CUR_LEVEL)

                // Active levels
                Log.d(LOG_TAG, "handleSyncFromDartToNative:start deal activeLevelsString\n")
                val activeLevelsString = call.argument<ArrayList<String>>(FgwConstant.ACTIVE_LEVELS)
                if (tmpCurGuardLevel != null && activeLevelsString != null) {
                    Log.d(LOG_TAG, "handleSyncFromDartToNative:tmpCurGuardLevel $tmpCurGuardLevel")
                    Log.d(LOG_TAG, "handleSyncFromDartToNative:activeLevelsString $activeLevelsString")

                    curGuardLevel = tmpCurGuardLevel.replace("\"", "").toInt()
                    FgwSeviceNotificationHandler.guardLevel = curGuardLevel
                    activeLevelsList = parseActiveLevelsString(activeLevelsString)
                } else {
                    Log.e(LOG_TAG, "Guard level or active levels string is null")
                }

                // Current entry file name
                Log.d(LOG_TAG, "handleSyncFromDartToNative:start deal Current entry file name\n")
                val tmpEntryFileName = call.argument<String>(FgwConstant.CUR_ENTRY_NAME)
                if (tmpEntryFileName != null) {
                    Log.d(LOG_TAG, "handleSyncFromDartToNative:tmpEntryFileName $tmpEntryFileName")
                    entryFilename = tmpEntryFileName
                } else {
                    Log.e(LOG_TAG, "Entry file name is null")
                }

                // Schedules
                Log.d(LOG_TAG, "handleSyncFromDartToNative:start deal Schedules\n ")
                val schedulesString = call.argument<ArrayList<String>>(FgwConstant.SCHEDULES)
                if (schedulesString != null) {
                    Log.d(LOG_TAG, "handleSyncFromDartToNative:schedulesString $schedulesString")
                    scheduleList = parseSchedulesString(schedulesString)
                    WallpaperScheduleHelper.handleSchedules(context, scheduleList)
                } else {
                    Log.e(LOG_TAG, "Schedules string is null")
                }

                Log.d(LOG_TAG, "handleSyncFromDartToNative:curGuardLevel $curGuardLevel")
                Log.d(LOG_TAG, "handleSyncFromDartToNative:activeLevelsList $activeLevelsList")
                Log.d(LOG_TAG, "handleSyncFromDartToNative:entryFilename $entryFilename")
                Log.d(LOG_TAG, "handleSyncFromDartToNative:scheduleList $scheduleList")

                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
                result.success(true)
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Exception in handleSyncFromDartToNative", e)
                result.error("ERROR", "Exception in handleSyncFromDartToNative: ${e.message}", e)
            }
        }
    }

    fun parseActiveLevelsString(activeLevelsString: ArrayList<String>): List<PrivacyGuardLevelRow> {
        val parsedItems = mutableListOf<PrivacyGuardLevelRow>()
        try {
            //val jsonArray = JSONArray(activeLevelsString)
            for (i in 0 until activeLevelsString.size) {
                val jsonObject = JSONObject(activeLevelsString[i])
//                val jsonObject = jsonArray.getJSONObject(i)
                val id = jsonObject.getInt("id")
                val level = jsonObject.getInt("guardLevel")
                val name = jsonObject.getString("labelName")
                val color = parseColorString(jsonObject.getString("color")) ?: 0
                val active = jsonObject.getInt("isActive") == 1
                val privacyGuardLevelRow = PrivacyGuardLevelRow(id, level, name, color, active)
                parsedItems.add(privacyGuardLevelRow)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Log.e(LOG_TAG, "Error parsing active levels string: ${e.message}")
        }
        return parsedItems
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

    fun parseSchedulesString(schedulesString: ArrayList<String>): List<WallpaperScheduleRow> {
        val parsedItems = mutableListOf<WallpaperScheduleRow>()
        try {
            for (i in 0 until schedulesString.size) {
                val jsonObject = JSONObject(schedulesString[i])
                val id = jsonObject.getInt("id")
                val order = jsonObject.getInt("orderNum")
                val label = jsonObject.getString("labelName")
                val guardLevelId = jsonObject.getInt("privacyGuardLevelId")
                val filterSetId = jsonObject.getInt("filtersSetId")
                val updateType = jsonObject.getString("updateType")
                val widgetId = jsonObject.getInt("widgetId")
                val displayType = jsonObject.getString("displayType")
                val interval = jsonObject.getInt("interval")
                val isActive = jsonObject.getInt("isActive") == 1
                val wallpaperScheduleRow = WallpaperScheduleRow(
                    id, order, label, guardLevelId, filterSetId, updateType, widgetId, displayType, interval, isActive
                )
                parsedItems.add(wallpaperScheduleRow)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            Log.e(LOG_TAG, "Error parsing schedules string: ${e.message}")
        }
        return parsedItems
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
        Log.d(LOG_TAG, "$opString [$context]:RUN")
        runBlocking {
            invokeFlutterMethod<Any>(context, FGWN_SERVICE_OP_CHANNEL,opString ,
                arguments = hashMapOf(
                    FgwConstant.newGuardLevel to newGuardLevel,
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
