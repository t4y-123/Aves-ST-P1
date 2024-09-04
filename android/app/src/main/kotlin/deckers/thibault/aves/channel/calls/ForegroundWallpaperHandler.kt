package deckers.thibault.aves.channel.calls


import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.app.Service
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import deckers.thibault.aves.ForegroundWallpaperService
import deckers.thibault.aves.ForegroundWallpaperTileService
import deckers.thibault.aves.ForegroundWallpaperWidgetProvider
import deckers.thibault.aves.fgw.FgwIntentAction
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.fgw.*
import deckers.thibault.aves.HomeWidgetProvider
import deckers.thibault.aves.utils.servicePendingIntent

class ForegroundWallpaperHandler(private val context: Context): MethodChannel.MethodCallHandler {

    private val appContext = context.applicationContext

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.i(LOG_TAG, "On ForegroundWallpaperHandler with call $call ")
        when (call.method) {
            "startForegroundWallpaper" -> {
                Log.i(LOG_TAG, "On startForegroundWallpaper")
                ForegroundWallpaperService.startForeground(appContext)
                result.success(null)
            }
            "stopForegroundWallpaper" -> {
                ForegroundWallpaperService.stop(appContext)
                Log.i(LOG_TAG, "Stop ForegroundWallpaper In Handler")
                result.success(null)
            }
            "update_widget" -> Coresult.safe(call, result, ::update_widget)
            // The getRunningServices method is indeed deprecated in newer Android versions (from API level 26 and onward)
            // due to changes in Android's background execution limits.
            // Though for backwards compatibility, it will still return the caller's own services.
            // Instead, you can manage the state of the service from within the service itself.
            // This is typically done by setting a static boolean variable to true when the service is running and to false when it's not.
            // As of  this method is no longer available to third party applications.
            "isForegroundWallpaperRunning" -> {
                result.success(ForegroundWallpaperService.isRunning)
            }
            "getAllWidgetIds" ->{
                result.success( getAllWidgetIds(appContext))
            }
            "setFgwGuardLevelLockState" -> {
                val isLocked = call.argument<Boolean>("isLocked") ?: false
                val action = if (isLocked) FgwIntentAction.LOCK else FgwIntentAction.UNLOCK
                val intent = Intent(appContext, ForegroundWallpaperTileService::class.java).apply {
                    this.action = action
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    appContext.startForegroundService(intent)
                } else {
                    appContext.startService(intent)
                }
                result.success(null)
            }

            FgwConstant.SYNC_FGW_SCHEDULE_CHANGES -> {
                val isTileRunning = ForegroundWallpaperTileService.getIsTileClickRunning(appContext)
                if (isTileRunning && ForegroundWallpaperService.isRunning) {
                    Log.d(LOG_TAG, "${FgwConstant.SYNC_FGW_SCHEDULE_CHANGES} broadcast sent")
                    val intent = Intent(FgwConstant.SYNC_FGW_SCHEDULE_CHANGES)
                    appContext.sendBroadcast(intent)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    } // onMethodCall

    private fun update_widget(call: MethodCall, result: MethodChannel.Result) {
        val widgetId = call.argument<Int>("widgetId")
        if (widgetId == null) {
            result.error("update-args", "missing arguments", null)
            return
        }

        val appWidgetManager = AppWidgetManager.getInstance(context)
        ForegroundWallpaperWidgetProvider().onUpdate(context, appWidgetManager, intArrayOf(widgetId))
        result.success(null)
    }

    fun getAllWidgetIds(context: Context): Map<String, List<Int>> {
        val appWidgetManager = AppWidgetManager.getInstance(context)

        // ComponentNames of your widget providers
        val homeWidgetProvider = ComponentName(context, HomeWidgetProvider::class.java)
        val foregroundWallpaperWidgetProvider = ComponentName(context, ForegroundWallpaperWidgetProvider::class.java)

        // Get all widget IDs for each provider
        val homeWidgetIds = appWidgetManager.getAppWidgetIds(homeWidgetProvider).filter { isActiveWidget(it, context) }
        val foregroundWallpaperWidgetIds = appWidgetManager.getAppWidgetIds(foregroundWallpaperWidgetProvider).filter { isActiveWidget(it, context) }

        // Return a map with the provider names as keys and the active widget ID lists as values
        return mapOf(
            "homeWidgets" to homeWidgetIds,
            "foregroundWallpaperWidgets" to foregroundWallpaperWidgetIds
        )
    }

    private fun isActiveWidget(appWidgetId: Int, context: Context): Boolean {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetOptions = appWidgetManager.getAppWidgetOptions(appWidgetId)

        // Check if the widget is currently bound to the home screen
        return appWidgetOptions != null
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ForegroundWallpaperWidgetProvider>()
        const val CHANNEL = "deckers.thibault/aves/foreground_wallpaper_handler"
    }
}

