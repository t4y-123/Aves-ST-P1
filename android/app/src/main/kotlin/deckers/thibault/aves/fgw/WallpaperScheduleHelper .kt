package deckers.thibault.aves.fgw

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.work.*
import android.util.Log
import java.util.concurrent.TimeUnit
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.fgw.*
import deckers.thibault.aves.ForegroundWallpaperService
import deckers.thibault.aves.ForegroundWallpaperWidgetProvider
import deckers.thibault.aves.utils.servicePendingIntent
import deckers.thibault.aves.utils.widgetPendingIntent
import deckers.thibault.aves.utils.getExistingPendingIntent
import android.appwidget.AppWidgetManager

// Define the WallpaperWorker class
class WallpaperWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    private val LOG_TAG = LogUtils.createTag<WallpaperWorker>()

    override fun doWork(): Result {
        Log.d(LOG_TAG, "doWork: WorkManager task executed")
        val intent = Intent(applicationContext, ForegroundWallpaperService::class.java).apply {
            action = FgwIntentAction.NEXT
        }
        applicationContext.startService(intent)
        return Result.success()
    }
}

class UpdateWidgetWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    private val LOG_TAG = LogUtils.createTag<UpdateWidgetWorker>()

    override fun doWork(): Result {
        val widgetId = inputData.getInt("widgetId", FgwConstant.NOT_WIDGET_ID)
        Log.d(LOG_TAG, "doWork: Updating widget with ID $widgetId")

        if (widgetId == FgwConstant.NOT_WIDGET_ID) {
            Log.e(LOG_TAG, "doWork: Invalid widget ID, cannot update widget")
            return Result.failure()
        }

        // Create an intent to update the widget
        val intent = Intent(applicationContext, ForegroundWallpaperWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
        }

        // Send the broadcast to update the widget
        applicationContext.sendBroadcast(intent)
        Log.d(LOG_TAG, "doWork: Widget update broadcast sent for widget ID $widgetId")

        return Result.success()
    }
}

object WallpaperScheduleHelper {
    private val LOG_TAG = LogUtils.createTag<WallpaperScheduleHelper>()

    fun handleSchedules(context: Context, scheduleList: List<WallpaperScheduleRow>) {
        Log.i(LOG_TAG, "handleSchedules with scheduleList [$scheduleList]  context [$context]")

        val homeKey = FgwConstant.getHomeScheduleKey(context)
        val lockKey = FgwConstant.getLockScheduleKey(context)
        val bothKey = FgwConstant.getBothScheduleKey(context)

        scheduleList.forEach { schedule ->
            val key = "${context.packageName}-${schedule.updateType}-${schedule.widgetId}"
            if (key == homeKey || key == lockKey) cancelWorkAndAlarmForHomeAndLock(context)
            if (key == bothKey) cancelWorkAndAlarmForBoth(context)
            Log.i(LOG_TAG, "handleSchedules key[$key]  schedule [$schedule]")
            when {
                schedule.interval >= 15 * 60 -> handleWorkManager(context, schedule, key)
                schedule.interval in 1 until 15 * 60 -> handleAlarmManager(context, schedule, key)
                else -> cancelWorkAndAlarm(context, key)
            }
        }
    }

    private fun handleWorkManager(context: Context, schedule: WallpaperScheduleRow, key: String) {
        Log.i(LOG_TAG, "handleWorkManager with key [$key]  schedule [$schedule]")
        val workManager = WorkManager.getInstance(context)

        // Always cancel the existing AlarmManager
        cancelAlarmWork(context, key)

        // Check for existing WorkManager
        val workInfoList = workManager.getWorkInfosForUniqueWork(key).get()
        if (workInfoList.isNotEmpty()) {
            Log.d(LOG_TAG, "WorkManager with key $key already exists, returning.")
            return
        }

        // Create a new WorkManager
        val workRequest = if (schedule.updateType == FgwConstant.CUR_TYPE_WIDGET) {
            PeriodicWorkRequestBuilder<UpdateWidgetWorker>(schedule.interval.toLong(), TimeUnit.SECONDS)
                .setInputData(workDataOf("widgetId" to schedule.widgetId))
                .build()
        } else {
            PeriodicWorkRequestBuilder<WallpaperWorker>(schedule.interval.toLong(), TimeUnit.SECONDS)
                .setInputData(workDataOf("interval" to schedule.interval))
                .build()
        }

        workManager.enqueueUniquePeriodicWork(key, ExistingPeriodicWorkPolicy.REPLACE, workRequest)
        Log.d(LOG_TAG, "handleWorkManager: WorkManager task scheduled with key $key")
    }

    private fun handleAlarmManager(context: Context, schedule: WallpaperScheduleRow, key: String) {
        Log.i(LOG_TAG, "handleAlarmManager with key [$key]  schedule [$schedule]")
        val workManager = WorkManager.getInstance(context)

        // Always cancel the existing WorkManager
        workManager.cancelUniqueWork(key)

        // Check for existing AlarmManager
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val pendingIntent = if (schedule.updateType == FgwConstant.CUR_TYPE_WIDGET) {
            context.widgetPendingIntent<ForegroundWallpaperWidgetProvider>(schedule.widgetId, key.hashCode())
        } else {
            context.servicePendingIntent<ForegroundWallpaperService>(FgwIntentAction.NEXT, key.hashCode())
        }
        pendingIntent?.let {
            alarmManager.setInexactRepeating(
                AlarmManager.RTC,
                System.currentTimeMillis(),
                schedule.interval * 1000L,
                it
            )
            Log.d(
                LOG_TAG,
                "handleAlarmManager: AlarmManager task scheduled with key $key and schedule.interval ${schedule.interval}"
            )
        } ?: Log.e(LOG_TAG, "handleAlarmManager: Failed to schedule AlarmManager task for key: $key")
    }


    private fun cancelAlarmWork(context: Context, key: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = getExistingPendingIntent(context, key)
        pendingIntent?.let {
            alarmManager.cancel(it)
            Log.d(LOG_TAG, "cancelAlarmWork: AlarmManager task cancelled with key $key")
        }
    }

    private fun cancelWorkManager(context: Context, key: String) {
        WorkManager.getInstance(context).cancelUniqueWork(key)
        Log.d(LOG_TAG, "cancelWorkManager: WorkManager task cancelled with key $key")
    }

    private fun cancelWorkAndAlarm(context: Context, key: String) {
        Log.d(LOG_TAG, "cancelWorkAndAlarm key [{$key}] context [${context}] ")
        cancelWorkManager(context, key)
        cancelAlarmWork(context, key)
    }

    private fun cancelWorkAndAlarmForBoth(context: Context) {
        cancelWorkAndAlarm(context, FgwConstant.getHomeScheduleKey(context))
        cancelWorkAndAlarm(context, FgwConstant.getLockScheduleKey(context))
    }

    private fun cancelWorkAndAlarmForHomeAndLock(context: Context) {
        cancelWorkAndAlarm(context, FgwConstant.getBothScheduleKey(context))
    }

    private fun getExistingPendingIntent(context: Context, key: String): PendingIntent? {
        Log.d(LOG_TAG, "getExistingPendingIntent key [${key}] key.hashCode() [${key.hashCode()}] context [$context]")
        val returnPendingIntent =
            context.getExistingPendingIntent<ForegroundWallpaperService>(FgwIntentAction.NEXT, key.hashCode())
        Log.d(LOG_TAG, "getExistingPendingIntent returnPendingIntent [${returnPendingIntent}] ")
        return returnPendingIntent
    }

    fun cancelFgwServiceRelateSchedule(context: Context) {
        Log.d(LOG_TAG, "cancelFgwServiceRelateSchedule context [${context}] ")

        // Cancel all schedules from the current schedule list in FgwServiceFlutterHandler
        FgwServiceFlutterHandler.scheduleList.forEach { schedule ->
            val key = "${context.packageName}-${schedule.updateType}-${schedule.widgetId}"
            cancelWorkAndAlarm(context, key)
        }
    }


    fun handleScreenEvents(context: Context, scheduleList: List<WallpaperScheduleRow>) {
        Log.d(LOG_TAG, "handleScreenEvents scheduleList [{$scheduleList}] context [${context}] ")
        val flutterKey = "${FgwServiceFlutterHandler.curUpdateType}-${FgwServiceFlutterHandler.curWidgetId}"
        scheduleList.forEach { schedule ->
            if (schedule.interval == 0) {
                val key = "${schedule.updateType}-${schedule.widgetId}"
                Log.d(LOG_TAG, "handleScreenEvents flutterKey [{$flutterKey}] key [${key}] ")
                cancelWorkAndAlarm(context, key)
                if (flutterKey == key) {
                    val intent = Intent(context, ForegroundWallpaperService::class.java).apply {
                        action = FgwIntentAction.NEXT
                    }
                    Log.d(LOG_TAG, "handleScreenEvents intent [{$intent}]")
                    context.startService(intent)
                }
            }
        }
    }
}