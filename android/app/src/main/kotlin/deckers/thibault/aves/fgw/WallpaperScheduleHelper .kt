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
import deckers.thibault.aves.utils.getExistWidgetPendingIntent
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
        val widgetId = inputData.getInt(FgwConstant.FGW_WIDGET_ID_EXTRA, FgwConstant.NOT_WIDGET_ID)
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

    fun handleSchedules(
        context: Context,
        scheduleList: List<WallpaperScheduleRow>,
        forceReplace: Boolean = false
    ) {
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
                schedule.interval >= 15 * 60 -> handleWorkManager(context, schedule, key, forceReplace)
                schedule.interval in 1 until 15 * 60 -> handleAlarmManager(context, schedule, key, forceReplace)
                else -> cancelWorkAndAlarm(context, key)
            }
        }
    }

    private fun handleWorkManager(
        context: Context,
        schedule: WallpaperScheduleRow,
        key: String,
        forceReplace: Boolean = false
    ) {
        Log.i(LOG_TAG, "handleWorkManager with key [$key]  schedule [$schedule]")
        val workManager = WorkManager.getInstance(context)
        val updateType = key.split("-")[1]
        val widgetId = key.split("-")[2].toIntOrNull() ?: FgwConstant.NOT_WIDGET_ID

        // Always cancel the existing AlarmManager
        cancelAlarmWork(context, key)

        // Check for existing WorkManager
        val workInfoList = workManager.getWorkInfosForUniqueWork(key).get()
        if (workInfoList.isNotEmpty()) {
            Log.d(LOG_TAG, "WorkManager with key $key already exists, $workInfoList.")
            // Check if we should force the replacement of the alarm
            if (forceReplace) {
                Log.d(LOG_TAG, "forceReplace is true, canceling existing handleWorkManager task.")
                workManager.cancelUniqueWork(key)
            } else {
                Log.d(LOG_TAG, "Skipping AlarmManager creation since forceReplace is false.")
                return
            }
        }

        // Create a new WorkManager
        val workRequest = if (schedule.updateType == FgwConstant.CUR_TYPE_WIDGET) {
            PeriodicWorkRequestBuilder<UpdateWidgetWorker>(schedule.interval.toLong(), TimeUnit.SECONDS)
                .setInputData(workDataOf(FgwConstant.FGW_WIDGET_ID_EXTRA to schedule.widgetId))
                .build()
        } else {
            PeriodicWorkRequestBuilder<WallpaperWorker>(schedule.interval.toLong(), TimeUnit.SECONDS)
                .setInputData(
                    workDataOf(
                        FgwConstant.FGW_UPDATE_TYPE_EXTRA to updateType,
                        FgwConstant.FGW_WIDGET_ID_EXTRA to widgetId,
                        FgwConstant.FGW_INTERVAL_EXTRA to schedule.interval
                    )
                )
                .build()
        }

        workManager.enqueueUniquePeriodicWork(key, ExistingPeriodicWorkPolicy.REPLACE, workRequest)
        triggerImmediateWork(context, schedule, key) // Trigger immediate work after scheduling
        Log.d(LOG_TAG, "handleWorkManager: WorkManager task scheduled with key $key")
    }

    private fun triggerImmediateWork(context: Context, schedule: WallpaperScheduleRow, key: String) {
        Log.i(LOG_TAG, "triggerImmediateWork with key [$key]  schedule [$schedule]")
        val workManager = WorkManager.getInstance(context)
        val updateType = key.split("-")[1]
        val widgetId = key.split("-")[2].toIntOrNull() ?: FgwConstant.NOT_WIDGET_ID

        val oneTimeWorkRequest = if (schedule.updateType == FgwConstant.CUR_TYPE_WIDGET) {
            OneTimeWorkRequestBuilder<UpdateWidgetWorker>()
                .setInputData(workDataOf(FgwConstant.FGW_WIDGET_ID_EXTRA to schedule.widgetId))
                .build()
        } else {
            OneTimeWorkRequestBuilder<WallpaperWorker>()
                .setInputData(
                    workDataOf(
                        FgwConstant.FGW_UPDATE_TYPE_EXTRA to updateType,
                        FgwConstant.FGW_WIDGET_ID_EXTRA to widgetId,
                        FgwConstant.FGW_INTERVAL_EXTRA to schedule.interval
                    )
                )
                .build()
        }

        // Enqueue the one-time work request to run immediately
        workManager.enqueue(oneTimeWorkRequest)
        Log.d(LOG_TAG, "triggerImmediateWork: One-time task triggered with key $key")
    }


    private fun handleAlarmManager(
        context: Context, schedule: WallpaperScheduleRow, key: String,
        forceReplace: Boolean = false
    ) {
        Log.i(LOG_TAG, "handleAlarmManager with key [$key]  schedule [$schedule]")
        val workManager = WorkManager.getInstance(context)

        // Always cancel the existing WorkManager
        workManager.cancelUniqueWork(key)

        // Check for existing AlarmManager
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val existingPendingIntent = getExistingPendingIntent(context, key)


        if (existingPendingIntent != null) {
            Log.d(LOG_TAG, "AlarmManager task with key $key already exists, skipping creation.")
            // Check if we should force the replacement of the alarm
            if (forceReplace) {
                Log.d(LOG_TAG, "forceReplace is true, canceling existing AlarmManager task.")
                alarmManager.cancel(existingPendingIntent)
            } else {
                Log.d(LOG_TAG, "Skipping AlarmManager creation since forceReplace is false.")
                return
            }
        }
        val updateType = schedule.updateType ?: key.split("-")[1]
        val widgetId = schedule.widgetId ?: key.split("-").getOrNull(2)?.toIntOrNull() ?: FgwConstant.NOT_WIDGET_ID

        triggerImmediateTask(context, schedule)
        // Create a new AlarmManager task
        val pendingIntent = if (schedule.updateType == FgwConstant.CUR_TYPE_WIDGET) {
            context.widgetPendingIntent<ForegroundWallpaperWidgetProvider>(schedule.widgetId, key.hashCode())
        } else {
            context.servicePendingIntent<ForegroundWallpaperService>(FgwIntentAction.NEXT, key.hashCode()) {
                putExtra(FgwConstant.FGW_UPDATE_TYPE_EXTRA, updateType)
                putExtra(FgwConstant.FGW_WIDGET_ID_EXTRA, widgetId)
            }
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

    private fun triggerImmediateTask(context: Context, schedule: WallpaperScheduleRow) {
        Log.i(LOG_TAG, "triggerImmediateTask: triggering task immediately $schedule")

        // Directly trigger the service or widget update
        if (schedule.updateType == FgwConstant.CUR_TYPE_WIDGET) {
            // Update the widget directly
            val intent = Intent(context, ForegroundWallpaperWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(schedule.widgetId))
            }
            context.sendBroadcast(intent)
        } else {
            // Start the service directly
            val intent = Intent(context, ForegroundWallpaperService::class.java).apply {
                action = FgwIntentAction.NEXT
                putExtra(FgwConstant.FGW_UPDATE_TYPE_EXTRA, schedule.updateType)  // Add updateType to the intent
                putExtra(FgwConstant.FGW_WIDGET_ID_EXTRA, schedule.widgetId)  // Add widgetId to the intent
            }
            context.startService(intent)
        }
    }

    private fun cancelAlarmWork(context: Context, key: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = getExistingPendingIntent(context, key)
        pendingIntent?.let {
            alarmManager.cancel(it)
            Log.d(LOG_TAG, "cancelAlarmWork: AlarmManager task cancelled with key $key [$it]")
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

    private fun getExistingPendingIntent(
        context: Context,
        key: String
    ): PendingIntent? {
        Log.d(LOG_TAG, "getExistingPendingIntent key [$key], hashCode: [${key.hashCode()}], context: [$context]")

        // Extract widgetId from key if it contains "-widget-"
        val widgetId = if (key.contains("-widget-")) {
            val regex = "-widget-(\\d+)".toRegex()
            val matchResult = regex.find(key)
            matchResult?.groupValues?.get(1)?.toIntOrNull() ?: -1 // Default to -1 if not found or invalid
        } else {
            -1
        }

        return if (widgetId != -1) {
            // Return PendingIntent for ForegroundWallpaperWidgetProvider (widget update)
            context.getExistWidgetPendingIntent<ForegroundWallpaperWidgetProvider>(
                widgetId,
                key.hashCode()
            ).also {
                Log.d(LOG_TAG, "Returning PendingIntent for widget, key: [$key], widgetId: [$widgetId]")
            }
        } else {
            // Return PendingIntent for ForegroundWallpaperService (service update)
            context.getExistingPendingIntent<ForegroundWallpaperService>(
                FgwIntentAction.NEXT,
                key.hashCode()
            ).also {
                Log.d(LOG_TAG, "Returning PendingIntent for service, action: [${FgwIntentAction.NEXT}], key: [$key]")
            }
        }.also {
            Log.d(LOG_TAG, "Returned PendingIntent: [$it]")
        }
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