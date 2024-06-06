package deckers.thibault.aves.channel.calls

import android.content.Context
import android.app.Service
import android.app.PendingIntent
import android.content.Intent
import android.widget.Toast;
import androidx.core.content.ContextCompat
import deckers.thibault.aves.ForegroundWallpaperService
import deckers.thibault.aves.ForegroundWallpaperWidgetProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import deckers.thibault.aves.utils.LogUtils
import android.appwidget.AppWidgetManager

// t4y : to make the service keep running even when the app is stop,
// use boardcast receriver to start the service
class ForegroundWallpaperHandler(private val context: Context): MethodChannel.MethodCallHandler {

    private val appContext = context.applicationContext

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.i(LOG_TAG, "On ForegroundWallpaperHandler")
        when (call.method) {
            "startForegroundWallpaper" -> {
                Log.i(LOG_TAG, "On startForegroundWallpaper")
                val serviceIntent = Intent(appContext, ForegroundWallpaperWidgetProvider::class.java)
                serviceIntent.action = ForegroundWallpaperWidgetProvider.ACTION_START_FOREGROUND
                appContext.sendBroadcast(serviceIntent)
                Toast.makeText(appContext, "Start ForegroundWallpaper In Handler", Toast.LENGTH_SHORT).show()
                result.success(null)
            }
            "stopForegroundWallpaper" -> {
                Log.i(LOG_TAG, "On stopForegroundWallpaper")
                val serviceIntent = Intent(appContext, ForegroundWallpaperWidgetProvider::class.java)
                serviceIntent.action = ForegroundWallpaperWidgetProvider.ACTION_STOP_FOREGROUND
                appContext.sendBroadcast(serviceIntent)
                Toast.makeText(appContext, "Stop ForegroundWallpaper In Handler", Toast.LENGTH_SHORT).show()
                result.success(null)
            }
            "update" -> Coresult.safe(call, result, ::update)
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

    private fun update(call: MethodCall, result: MethodChannel.Result) {
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
        const val FOREGROUND_WALLPAPER_ACTION = "deckers.thibault.aves.FOREGROUND_WALLPAPER_ACTION"
        const val CHANNEL = "deckers.thibault/aves/foreground_wallpaper_handler"
    }
}

