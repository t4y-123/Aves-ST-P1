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

object WallpaperScheduleHelper {
    private val LOG_TAG = LogUtils.createTag<WallpaperScheduleHelper>()

    fun handleSchedules(context: Context, scheduleList: List<WallpaperScheduleRow>) {
        Log.i(LOG_TAG, "handleSchedules with scheduleList [$scheduleList]  context [$context]")
        scheduleList.forEach { schedule ->
            val key = "${schedule.updateType}-${schedule.widgetId}"
            if(key ==  FgwConstant.home_schedule_key || key ==  FgwConstant.lock_schedule_key)  cancelWorkAndAlarmForHomeAndLock(context)
            if(key ==  FgwConstant.both_schedule_key)  cancelWorkAndAlarmForBoth(context)
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
        val workRequest = PeriodicWorkRequestBuilder<WallpaperWorker>(schedule.interval.toLong(), TimeUnit.SECONDS)
            .setInputData(workDataOf("interval" to schedule.interval))
            .build()
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
        val pendingIntent = getPendingIntent(context, key)

        if (pendingIntent != null) {
            Log.i(LOG_TAG, "AlarmManager with key $key already exists, returning.")
            return
        }

        // Set a new AlarmManager
        val intent = Intent(context, ForegroundWallpaperService::class.java).apply {
            action = FgwIntentAction.NEXT
        }

        val newPendingIntent = PendingIntent.getService(context, key.hashCode(), intent, PendingIntent.FLAG_UPDATE_CURRENT)
//        alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, System.currentTimeMillis(), schedule.interval * 1000L, newPendingIntent)
        alarmManager.setInexactRepeating(AlarmManager.RTC, System.currentTimeMillis(), schedule.interval * 1000L, newPendingIntent)
        Log.d(LOG_TAG, "handleAlarmManager: AlarmManager task scheduled with key $key and schedule.interval ${schedule.interval}")
    }

    private fun cancelAlarmWork(context: Context, key: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = getPendingIntent(context, key)
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
        cancelWorkAndAlarm(context, FgwConstant.home_schedule_key)
        cancelWorkAndAlarm(context, FgwConstant.lock_schedule_key)
    }

    private fun cancelWorkAndAlarmForHomeAndLock(context: Context) {
        cancelWorkAndAlarm(context, FgwConstant.both_schedule_key)
    }

    private fun getPendingIntent(context: Context, key: String): PendingIntent? {
        Log.d(LOG_TAG, "getPendingIntent key [${key}] key.hashCode() [${key.hashCode()}] context [$context]")
        val intent = Intent(context, ForegroundWallpaperService::class.java).apply {
            action = FgwIntentAction.NEXT
        }
        val returnPendingIntent = PendingIntent.getService(context, key.hashCode(), intent, PendingIntent.FLAG_NO_CREATE)
        Log.d(LOG_TAG, "getPendingIntent returnPendingIntent [${returnPendingIntent}] ")
        return returnPendingIntent
    }

    fun cancelFgwServiceRelateSchedule(context: Context) {
        Log.d(LOG_TAG, "cancelFgwServiceRelateSchedule context [${context}] ")
        val homeKey = FgwConstant.home_schedule_key
        val lockKey = FgwConstant.lock_schedule_key
        val bothKey = FgwConstant.both_schedule_key
        cancelWorkAndAlarm(context, homeKey)
        cancelWorkAndAlarm(context, lockKey)
        cancelWorkAndAlarm(context, bothKey)
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