package deckers.thibault.aves.fgw

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.app.KeyguardManager
import android.widget.RemoteViews
import android.view.View
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import deckers.thibault.aves.MainActivity
import deckers.thibault.aves.R
import deckers.thibault.aves.ForegroundWallpaperService
import deckers.thibault.aves.fgw.FgwSeviceNotificationHandler.LayoutType
import deckers.thibault.aves.fgw.FgwSeviceNotificationHandler.isChangingGuardLevel
import deckers.thibault.aves.fgw.FgwSeviceNotificationHandler.isLevelGroup
import deckers.thibault.aves.fgw.FgwSeviceNotificationHandler.isScreenLocked
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.utils.activityPendingIntent
import deckers.thibault.aves.utils.servicePendingIntent

inline fun RemoteViews.setupButton(
    context: Context,
    buttonId: Int,
    iconResId: Int,
    action: String,
    isInactiveButton: Boolean,
    isActivityIntent: Boolean,
) {
    setImageViewResource(buttonId, iconResId)

    if (!isInactiveButton) {
        val pendingIntent = when {
            isActivityIntent -> {
                context.activityPendingIntent<MainActivity>(action)
            }
            else -> {context.servicePendingIntent<ForegroundWallpaperService>(action)}
        }
        setOnClickPendingIntent(buttonId,pendingIntent )
        setViewVisibility(buttonId, View.VISIBLE)
        setInt(buttonId, "setAlpha", 255) // Fully opaque
    } else {
        // Disable the button click by not setting a PendingIntent
        setOnClickPendingIntent(buttonId, null)
        setViewVisibility(buttonId, View.VISIBLE)
        setInt(buttonId, "setAlpha", 100)
    }
}

inline fun RemoteViews.setGroupBtns(
    context: Context,
    buttonActions: List<Triple<Int, Int, String>>,
    inactiveButtonResIds: Set<Int>,
    activityButtonResIds: Set<Int>,
) {
    buttonActions.forEach { (buttonId, iconResId, action) ->
        setupButton(
            context,
            buttonId,
            iconResId,
            action,
            inactiveButtonResIds.contains(iconResId),
            activityButtonResIds.contains(iconResId),
        )
    }
}

object FgwSeviceNotificationHandler {
    private val LOG_TAG = LogUtils.createTag<FgwSeviceNotificationHandler>()
    const val FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID = "foreground_wallpaper"
    const val NOTIFICATION_ID = 2

    var isGuardLevelLocked = true
    var isLevelGroup = false
    var isChangingGuardLevel = false
    var guardLevel: Int = 0

    // Inactive button IDs
    val inactiveButtonResIds = mutableSetOf<Int>()

    // Level changing button IDs
    private val levelButtonResId = setOf(
        R.drawable.baseline_arrow_downward_24, // DOWNWARD
        R.drawable.baseline_arrow_upward_24, // UPWARD
        R.drawable.baseline_check_24, // APPLY_LEVEL_CHANGE
    )
    private val activityButtonResIds = setOf(
        R.drawable.baseline_auto_stories_24,
        R.drawable.baseline_copy_all_24,
        R.drawable.baseline_lock_24
    )
    // used for unlock screen, easily to make wallpaper next or go into the related collection.
    private val normalLytEntryBtns = listOf(
        Triple(R.id.iv_normal_lyt_btn_01, R.drawable.baseline_pre_24, FgwIntentAction.PRE),
        Triple(R.id.iv_normal_lyt_btn_02, R.drawable.baseline_next_24, FgwIntentAction.NEXT),
        Triple(R.id.iv_normal_lyt_btn_03, R.drawable.baseline_copy_all_24, FgwIntentAction.DUPLICATE),
        Triple(R.id.iv_normal_lyt_btn_04, R.drawable.baseline_auto_stories_24, FgwIntentAction.USED_RECORD)
    )

    // used for phone lock screen, easily to change privacy guard level.
    private val normalLytLevelBtns = listOf(
        Triple(R.id.iv_normal_lyt_btn_01, R.drawable.baseline_arrow_downward_24, FgwIntentAction.DOWNWARD),
        Triple(R.id.iv_normal_lyt_btn_02, R.drawable.baseline_arrow_upward_24, FgwIntentAction.UPWARD),
        Triple(R.id.iv_normal_lyt_btn_03, R.drawable.baseline_lock_open_24, FgwIntentAction.LOCK),
        Triple(R.id.iv_normal_lyt_btn_04, R.drawable.baseline_next_24, FgwIntentAction.NEXT)
    )
    private val normalLytLevelChangingBtns = listOf(
        Triple(R.id.iv_normal_lyt_btn_01, R.drawable.baseline_arrow_downward_24, FgwIntentAction.DOWNWARD),
        Triple(R.id.iv_normal_lyt_btn_02, R.drawable.baseline_arrow_upward_24, FgwIntentAction.UPWARD),
        Triple(R.id.iv_normal_lyt_btn_03, R.drawable.baseline_close_24, FgwIntentAction.CANCEL_LEVEL_CHANGE),
        Triple(R.id.iv_normal_lyt_btn_04, R.drawable.baseline_check_24, FgwIntentAction.APPLY_LEVEL_CHANGE)
    )

    // by default, expand unlocked entry type layout.
    private val bigLytEntryBtns = listOf(
        Triple(R.id.iv_big_lyt_btn_01, R.drawable.baseline_menu_open_24, FgwIntentAction.SWITCH_GROUP),
        Triple(R.id.iv_big_lyt_btn_02, R.drawable.baseline_pre_24, FgwIntentAction.PRE),
        Triple(R.id.iv_big_lyt_btn_03, R.drawable.baseline_next_24, FgwIntentAction.NEXT),
        Triple(R.id.iv_big_lyt_btn_04, R.drawable.baseline_copy_all_24, FgwIntentAction.DUPLICATE),
        Triple(R.id.iv_big_lyt_btn_05, R.drawable.baseline_auto_stories_24, FgwIntentAction.USED_RECORD)
    )

    // else, expand privacy guard level modify type layout.
    private val bigLytLevelBtns = listOf(
        Triple(R.id.iv_big_lyt_btn_01, R.drawable.baseline_menu_open_24, FgwIntentAction.SWITCH_GROUP),
        Triple(R.id.iv_big_lyt_btn_02, R.drawable.baseline_arrow_downward_24, FgwIntentAction.DOWNWARD),
        Triple(R.id.iv_big_lyt_btn_03, R.drawable.baseline_arrow_upward_24, FgwIntentAction.UPWARD),
        Triple(R.id.iv_big_lyt_btn_04, R.drawable.baseline_lock_open_24, FgwIntentAction.LOCK),
        Triple(R.id.iv_big_lyt_btn_05, R.drawable.baseline_next_24, FgwIntentAction.NEXT)
    )

    private val bigLytLevelBtnsChanging = listOf(
        Triple(R.id.iv_big_lyt_btn_01, R.drawable.baseline_menu_open_24, FgwIntentAction.SWITCH_GROUP),
        Triple(R.id.iv_big_lyt_btn_02, R.drawable.baseline_arrow_downward_24, FgwIntentAction.DOWNWARD),
        Triple(R.id.iv_big_lyt_btn_03, R.drawable.baseline_arrow_upward_24, FgwIntentAction.UPWARD),
        Triple(R.id.iv_big_lyt_btn_04, R.drawable.baseline_close_24, FgwIntentAction.CANCEL_LEVEL_CHANGE),
        Triple(R.id.iv_big_lyt_btn_05, R.drawable.baseline_check_24, FgwIntentAction.APPLY_LEVEL_CHANGE)
    )

    enum class LayoutType {
        NORMAL_ENTRY, NORMAL_LEVEL, NORMAL_LEVEL_CHANGING, BIG_ENTRY, BIG_LEVEL, BIG_LEVEL_CHANGING
    }

    fun updateButtonbyDrawable(iconResId: Int, available: Boolean) {
        if (available) {
            inactiveButtonResIds.remove(iconResId)
        } else {
            inactiveButtonResIds.add(iconResId)
        }
    }

    fun createNotification(context: Context): Notification {
        //Log.d(LOG_TAG, "createNotification($context)")
        val builder =
            NotificationCompat.Builder(context, FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(
                    context.activityPendingIntent<MainActivity>( FgwConstant.FGW_VIEW_OPEN)
                )
                .setTicker("Ticker text")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setOngoing(true)

        val (normalLytType, bigLytType) = when {
            // use !NOT to make the line not too long split by format code.
            isLevelGroup && !isChangingGuardLevel-> LayoutType.NORMAL_LEVEL to LayoutType.BIG_LEVEL
            isLevelGroup  -> LayoutType.NORMAL_LEVEL_CHANGING to LayoutType.BIG_LEVEL_CHANGING
            isScreenLocked(context) && !isChangingGuardLevel -> LayoutType.NORMAL_LEVEL to LayoutType.BIG_LEVEL
            isScreenLocked(context) -> LayoutType.NORMAL_LEVEL_CHANGING to LayoutType.BIG_LEVEL_CHANGING
            else -> LayoutType.NORMAL_ENTRY to LayoutType.BIG_ENTRY
        }

        Log.d(
            LOG_TAG, "createNotification(isLevelGroup:$isLevelGroup)\n" +
                    "isChangingGuardLevel:$isChangingGuardLevel \n" +
                    "normalLytType $normalLytType \n" +
                    "bigLytType $bigLytType \n"
        )
        builder.setCustomContentView(getContentView(context, normalLytType))
        builder.setCustomBigContentView(getContentView(context, bigLytType))
        return builder.build()
    }

    fun updateNotificationFromStoredValues(context: Context) {
        //Log.d(LOG_TAG, "updateNotificationFromStoredValues($context)")
        val notification = createNotification(context)
        val notificationManager = NotificationManagerCompat.from(context)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }


    private fun updateGuardLevel(remoteViews: RemoteViews) {
        Log.d(LOG_TAG, "updateGuardLevel($remoteViews) $guardLevel \n updateGuardLevel(${FgwServiceFlutterHandler.activeLevelsList})")
        val minLevel = FgwServiceFlutterHandler.activeLevelsList.minByOrNull { it.level }?.level ?: 1
        val maxLevel = FgwServiceFlutterHandler.activeLevelsList.maxByOrNull { it.level }?.level ?: 1

        if(!isGuardLevelLocked){
            guardLevel = when {
                guardLevel >= maxLevel -> {
                    inactiveButtonResIds.add(R.drawable.baseline_arrow_upward_24)
                    maxLevel
                }
                guardLevel <= minLevel -> {
                    inactiveButtonResIds.add(R.drawable.baseline_arrow_downward_24)
                    minLevel
                }
                else -> {
                    inactiveButtonResIds.remove(R.drawable.baseline_arrow_upward_24)
                    inactiveButtonResIds.remove(R.drawable.baseline_arrow_downward_24)
                    guardLevel
                }
            }
        }

        val matchingLevel = FgwServiceFlutterHandler.activeLevelsList.find { it.level == guardLevel }
        Log.d(LOG_TAG, "updateGuardLeve minLevel ${minLevel} maxLevell: $maxLevel)" +
                "updateGuardLevel inactiveButtonResIds: ($inactiveButtonResIds)" +
                "updateGuardLevel matchingLevel ($matchingLevel)")

        matchingLevel?.let { level ->
           // Log.d(LOG_TAG, "updateGuardLevel level.level (${level.level})")
            remoteViews.setTextViewText(R.id.tv_status, level.level.toString())
            Log.d(LOG_TAG, "updateGuardLevel level.name (${level.name})")
            remoteViews.setTextViewText(R.id.tv_title, level.name)
            // Log.d(LOG_TAG, "updateGuardLevel level.color int: (${level.color})")
            remoteViews.setInt(R.id.tv_status, "setBackgroundColor", level.color)
            //Log.d(LOG_TAG, "updateGuardLevel remoteViews.setTextViewText(${R.id.tv_text}, (${FgwServiceFlutterHandler.entryFilename}))")
            remoteViews.setTextViewText(R.id.tv_text, FgwServiceFlutterHandler.entryFilename)
        }
    }

    private fun getContentView(context: Context, layoutType: LayoutType): RemoteViews {
        //Log.d(LOG_TAG, "getContentView($context)")
        val remoteViews = when (layoutType) {
            LayoutType.NORMAL_ENTRY, LayoutType.NORMAL_LEVEL, LayoutType.NORMAL_LEVEL_CHANGING ->
                RemoteViews(context.packageName, R.layout.fgw_notification_normal)

            LayoutType.BIG_ENTRY, LayoutType.BIG_LEVEL, LayoutType.BIG_LEVEL_CHANGING ->
                RemoteViews(context.packageName, R.layout.fgw_notification_big)
        }
        //Log.d(LOG_TAG, "getContentView($context)")

        val buttonActions = when (layoutType) {
            LayoutType.NORMAL_ENTRY -> normalLytEntryBtns
            LayoutType.NORMAL_LEVEL -> normalLytLevelBtns
            LayoutType.NORMAL_LEVEL_CHANGING -> normalLytLevelChangingBtns
            LayoutType.BIG_ENTRY -> bigLytEntryBtns
            LayoutType.BIG_LEVEL -> bigLytLevelBtns
            LayoutType.BIG_LEVEL_CHANGING -> bigLytLevelBtnsChanging
        }.map { Triple(it.first, it.second, it.third) }.toMutableList()

        if (isGuardLevelLocked) {
            inactiveButtonResIds += levelButtonResId
            when (layoutType) {
                // unlock is main activity , use FgwConstant not FgwIntentAction.
                LayoutType.NORMAL_LEVEL ->
                    buttonActions[2] =
                        Triple(buttonActions[2].first, R.drawable.baseline_lock_24, FgwConstant.FGW_UNLOCK)

                LayoutType.BIG_LEVEL ->
                    buttonActions[3] =
                        Triple(buttonActions[3].first, R.drawable.baseline_lock_24, FgwConstant.FGW_UNLOCK)

                else -> Log.i(LOG_TAG, " {$isGuardLevelLocked} isGuardLevelLocked layoutType($layoutType)")
            }
        } else {
            inactiveButtonResIds -= levelButtonResId
            when (layoutType) {
                LayoutType.NORMAL_LEVEL ->
                    buttonActions[2] =
                        Triple(buttonActions[2].first, R.drawable.baseline_lock_open_24, FgwIntentAction.LOCK)

                LayoutType.BIG_LEVEL ->
                    buttonActions[3] =
                        Triple(buttonActions[3].first, R.drawable.baseline_lock_open_24, FgwIntentAction.LOCK)

                else -> Log.i(LOG_TAG, " {$isGuardLevelLocked} isGuardLevelLocked layoutType($layoutType)")
            }
        }

        updateGuardLevel(remoteViews)
        remoteViews.setGroupBtns(context, buttonActions, inactiveButtonResIds, activityButtonResIds)
        return remoteViews
    }

    private fun isScreenLocked(context: Context): Boolean {
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }
}
