package deckers.thibault.aves.channel.calls

import android.content.Context
import android.app.Service
import android.app.PendingIntent
import android.content.Intent
import androidx.core.content.ContextCompat
import deckers.thibault.aves.ForegroundWallpaperService
import deckers.thibault.aves.ForegroundWallpaperWidgetProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import deckers.thibault.aves.utils.LogUtils
import android.appwidget.AppWidgetManager

class ForegroundWallpaperHandler(private val context: Context): MethodChannel.MethodCallHandler {

    private val appContext = context.applicationContext

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.i(LOG_TAG, "On ForegroundWallpaperHandler")
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

    companion object {
        private val LOG_TAG = LogUtils.createTag<ForegroundWallpaperWidgetProvider>()
        const val CHANNEL = "deckers.thibault/aves/foreground_wallpaper_handler"
    }
}

