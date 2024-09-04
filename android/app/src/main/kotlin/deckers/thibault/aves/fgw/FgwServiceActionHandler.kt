package deckers.thibault.aves.fgw

import android.app.Service
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import deckers.thibault.aves.utils.LogUtils

import deckers.thibault.aves.channel.calls.MetadataFetchHandler
import deckers.thibault.aves.channel.calls.GeocodingHandler

object FgwServiceActionHandler {
    private val LOG_TAG = LogUtils.createTag<FgwServiceActionHandler>()

    fun handleStartCommand(context: Context, intent: Intent?, flags: Int, startId: Int) {
//        if(intent?.action!=null && intent?.action!= FgwIntentAction.SWITCH_GROUP)
//            showToast(context, "${intent!!.action} tapped")
        when (intent?.action) {
            FgwIntentAction.SWITCH_GROUP -> {
                FgwSeviceNotificationHandler.isLevelGroup = !FgwSeviceNotificationHandler.isLevelGroup
            }
            FgwIntentAction.PRE -> {
                FgwServiceFlutterHandler.handleWallpaper(context,FgwConstant.PRE_WARLLPAPER)
            }
            FgwIntentAction.NEXT -> {
                FgwServiceFlutterHandler.handleWallpaper(context,FgwConstant.NEXT_WARLLPAPER)
            }
            FgwIntentAction.DOWNWARD -> {
                FgwSeviceNotificationHandler.isChangingGuardLevel = true
                FgwSeviceNotificationHandler.guardLevel -= 1
            }
            FgwIntentAction.UPWARD -> {
                FgwSeviceNotificationHandler.isChangingGuardLevel = true
                FgwSeviceNotificationHandler.guardLevel += 1
            }
            FgwIntentAction.CANCEL_LEVEL_CHANGE -> {
                // cancel change guard level get back the curGuardLevel.
                FgwSeviceNotificationHandler.guardLevel = FgwServiceFlutterHandler.curGuardLevel
                FgwSeviceNotificationHandler.isChangingGuardLevel = false
            }
            FgwIntentAction.APPLY_LEVEL_CHANGE -> {
                //cancel all schedule periodic work, then set the level.
                // in dart side, the flutter changeGuardLevel will call the next wallpaper to refresh the wallpaper.
                WallpaperScheduleHelper.cancelFgwServiceRelateSchedule(context)
                FgwServiceFlutterHandler.curGuardLevel = FgwSeviceNotificationHandler.guardLevel
                FgwSeviceNotificationHandler.isChangingGuardLevel = false
                FgwServiceFlutterHandler.changeGuardLevel(context,FgwServiceFlutterHandler.curGuardLevel)
            }
            FgwIntentAction.LOCK -> {
                FgwSeviceNotificationHandler.isGuardLevelLocked = true;
                FgwServiceFlutterHandler.callDartNoArgsMethod(context,FgwConstant.FGW_LOCK)
//                showToast(context,if (FgwSeviceNotificationHandler.isGuardLevelLocked) "Locked" else "Unlocked")
            }
            FgwIntentAction.UNLOCK -> {
                FgwSeviceNotificationHandler.isGuardLevelLocked = false;
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
//                showToast(context,if (FgwSeviceNotificationHandler.isGuardLevelLocked) "Locked" else "Unlocked")
            }
            FgwIntentAction.SYNC_FGW_SCHEDULE_CHANGES -> {
                FgwServiceFlutterHandler.callDartNoArgsMethod(context,FgwConstant.SYNC_FGW_SCHEDULE_CHANGES)
            }
            Intent.ACTION_SCREEN_ON -> handleScreenOn(context)
            Intent.ACTION_SCREEN_OFF -> handleScreenOff(context)
            Intent.ACTION_USER_PRESENT -> handleUserPresent(context)
        }
        FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
    }

    private fun handleScreenOn(context:Context) {
        // Handle screen on event
        Log.i(LOG_TAG, "Screen ON")
        FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
        WallpaperScheduleHelper.handleSchedules(context,FgwServiceFlutterHandler.scheduleList)
    }

    private fun handleScreenOff(context:Context) {
        // Handle screen off event
        Log.i(LOG_TAG, "Screen OFF")
        FgwServiceFlutterHandler.curUpdateType = FgwConstant.CUR_TYPE_LOCK
        FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
        WallpaperScheduleHelper.handleScreenEvents(context,FgwServiceFlutterHandler.scheduleList)
    }

    private fun handleUserPresent(context:Context) {
        // Handle user present (unlock) event
        Log.i(LOG_TAG, "User Present (Unlocked)")
        FgwServiceFlutterHandler.curUpdateType = FgwConstant.CUR_TYPE_HOME
        FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
        WallpaperScheduleHelper.handleScreenEvents(context,FgwServiceFlutterHandler.scheduleList)
    }
}
