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
        when (intent?.action) {
            FgwIntentAction.SWITCH_GROUP -> {
                FgwSeviceNotificationHandler.isLevelGroup = !FgwSeviceNotificationHandler.isLevelGroup
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.LEFT -> {
                showToast(context, "Left arrow tapped")
                FgwServiceFlutterHandler.preWallpaper(context)
                //FgwServiceFlutterHandler.updateNotificationFromDart(context)// Add this line
            }
            FgwIntentAction.RIGHT -> {
                showToast(context, "Right arrow tapped")
                FgwServiceFlutterHandler.nextWallpaper(context)
                //FgwServiceFlutterHandler.updateNotificationFromDart(context)// Add this line
            }
            FgwIntentAction.USED_RECORD -> {
                showToast(context, "USED_RECORD icon tapped")
                FgwServiceFlutterHandler.updateNotificationFromDart(context)
            }
            FgwIntentAction.DOWNWARD -> {
                FgwSeviceNotificationHandler.isChangingGuardLevel = true
                FgwSeviceNotificationHandler.guardLevel -= 1
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.UPWARD -> {
                FgwSeviceNotificationHandler.isChangingGuardLevel = true
                FgwSeviceNotificationHandler.guardLevel += 1
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.CANCEL_LEVEL_CHANGE -> {
                FgwSeviceNotificationHandler.guardLevel = FgwServiceFlutterHandler.curGuardLevel
                FgwSeviceNotificationHandler.isChangingGuardLevel = false
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.APPLY_LEVEL_CHANGE -> {
                //FgwSeviceNotificationHandler.guardLevel = FgwSeviceNotificationHandler.guardLevel
                FgwSeviceNotificationHandler.isChangingGuardLevel = false
                FgwServiceFlutterHandler.syncNecessaryDataFromDart(context)
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }
            FgwIntentAction.LOCK_UNLOCK -> {
                FgwSeviceNotificationHandler.canChangeLevel = !FgwSeviceNotificationHandler.canChangeLevel
                showToast(context,if (FgwSeviceNotificationHandler.canChangeLevel) "Locked" else "Unlocked")
                FgwSeviceNotificationHandler.updateNotificationFromStoredValues(context)
            }

            Intent.ACTION_SCREEN_ON -> handleScreenOn(context)
            Intent.ACTION_SCREEN_OFF -> handleScreenOff(context)
            Intent.ACTION_USER_PRESENT -> handleUserPresent(context)
        }
    }

    private fun handleScreenOn(context:Context) {
        // Handle screen on event
        Log.i(LOG_TAG, "Screen ON")
        FgwServiceFlutterHandler.updateNotificationFromDart(context)
    }

    private fun handleScreenOff(context:Context) {
        // Handle screen off event
        Log.i(LOG_TAG, "Screen OFF")
        FgwServiceFlutterHandler.updateNotificationFromDart(context)
    }

    private fun handleUserPresent(context:Context) {
        // Handle user present (unlock) event
        Log.i(LOG_TAG, "User Present (Unlocked)")
        FgwServiceFlutterHandler.updateNotificationFromDart(context)
    }

    private fun showToast(context:Context, message: String) {
        Log.i(LOG_TAG, "FgwServiceActionHandler $context : $message")
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
}
