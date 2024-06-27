package deckers.thibault.aves.fgw

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.app.KeyguardManager
import android.widget.RemoteViews
import android.view.View
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import deckers.thibault.aves.MainActivity
import deckers.thibault.aves.R
import deckers.thibault.aves.ForegroundWallpaperService
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.utils.activityPendingIntent
import deckers.thibault.aves.utils.servicePendingIntent

inline fun RemoteViews.setupButton(
    context: Context,
    buttonId: Int,
    iconResId: Int,
    action: String,
    canChangeLevel: Boolean,
    isLevelButton: Boolean,
    isLevelGroup: Boolean
) {
    setImageViewResource(buttonId, iconResId)
    if (!isLevelGroup || canChangeLevel || !isLevelButton) {
        setOnClickPendingIntent(
            buttonId,
            context.servicePendingIntent<ForegroundWallpaperService>(action)
        )
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
    canChangeLevel: Boolean,
    isLevelGroup: Boolean,
    levelButtonResId: Set<Int>
) {
    buttonActions.forEach { (buttonId, iconResId, action) ->
        setupButton(context, buttonId, iconResId, action, canChangeLevel,isLevelGroup, levelButtonResId.contains(iconResId))
    }
}

object FgwSeviceNotificationHandler {
    private val LOG_TAG = LogUtils.createTag<FgwSeviceNotificationHandler>()
    const val FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID = "foreground_wallpaper"
    const val NOTIFICATION_ID = 2

    var canChangeLevel = true
    var isLevelGroup = false
    var isChangingGuardLevel = false
    var guardLevel: String = "0"
    var tmpGuardLevel = 1
    var titleName: String = "Guard Level"
    var color: Int = android.R.color.darker_gray

    // Level changing button IDs
    private val levelButtonResId = setOf(
        R.drawable.baseline_arrow_downward_24, // DOWNWARD
        R.drawable.baseline_arrow_upward_24, // UPWARD
        R.drawable.baseline_check_24, // APPLY_LEVEL_CHANGE
    )
    // used for unlock screen, easily to make wallpaper next or go into the related collection.
    private val normalLytEntryBtns = listOf(
        Triple(R.id.iv_normal_lyt_btn_01, R.drawable.baseline_navigate_before_24, FgwIntentAction.LEFT),
        Triple(R.id.iv_normal_lyt_btn_02, R.drawable.baseline_navigate_next_24, FgwIntentAction.RIGHT),
        Triple(R.id.iv_normal_lyt_btn_03, R.drawable.baseline_add_photo_24, FgwIntentAction.DUPLICATE),
        Triple(R.id.iv_normal_lyt_btn_04, R.drawable.baseline_auto_stories_24, FgwIntentAction.STORES)
    )
    // used for phone lock screen, easily to change privacy guard level.
    private val normalLytLevelBtns = listOf(
        Triple(R.id.iv_normal_lyt_btn_01, R.drawable.baseline_arrow_downward_24, FgwIntentAction.DOWNWARD),
        Triple(R.id.iv_normal_lyt_btn_02, R.drawable.baseline_arrow_upward_24, FgwIntentAction.UPWARD),
        Triple(R.id.iv_normal_lyt_btn_03, R.drawable.baseline_lock_open_24, FgwIntentAction.LOCK_UNLOCK),
        Triple(R.id.iv_normal_lyt_btn_04, R.drawable.baseline_navigate_next_24, FgwIntentAction.RIGHT)
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
        Triple(R.id.iv_big_lyt_btn_02, R.drawable.baseline_navigate_before_24, FgwIntentAction.LEFT),
        Triple(R.id.iv_big_lyt_btn_03, R.drawable.baseline_navigate_next_24, FgwIntentAction.RIGHT),
        Triple(R.id.iv_big_lyt_btn_04, R.drawable.baseline_add_photo_24, FgwIntentAction.DUPLICATE),
        Triple(R.id.iv_big_lyt_btn_05, R.drawable.baseline_auto_stories_24, FgwIntentAction.STORES)
    )
    // else, expand privacy guard level modify type layout.
    private val bigLytLevelBtns = listOf(
        Triple(R.id.iv_big_lyt_btn_01, R.drawable.baseline_menu_open_24, FgwIntentAction.SWITCH_GROUP),
        Triple(R.id.iv_big_lyt_btn_02, R.drawable.baseline_arrow_downward_24, FgwIntentAction.DOWNWARD),
        Triple(R.id.iv_big_lyt_btn_03, R.drawable.baseline_arrow_upward_24, FgwIntentAction.UPWARD),
        Triple(R.id.iv_big_lyt_btn_04, R.drawable.baseline_lock_open_24, FgwIntentAction.LOCK_UNLOCK),
        Triple(R.id.iv_big_lyt_btn_05, R.drawable.baseline_navigate_next_24, FgwIntentAction.RIGHT)
    )

    private val bigLytLevelBtnsChanging = listOf(
        Triple(R.id.iv_big_lyt_btn_01, R.drawable.baseline_menu_open_24, FgwIntentAction.SWITCH_GROUP),
        Triple(R.id.iv_big_lyt_btn_02, R.drawable.baseline_arrow_downward_24, FgwIntentAction.DOWNWARD),
        Triple(R.id.iv_big_lyt_btn_03, R.drawable.baseline_arrow_upward_24, FgwIntentAction.UPWARD),
        Triple(R.id.iv_big_lyt_btn_04, R.drawable.baseline_close_24, FgwIntentAction.CANCEL_LEVEL_CHANGE),
        Triple(R.id.iv_big_lyt_btn_05, R.drawable.baseline_check_24, FgwIntentAction.APPLY_LEVEL_CHANGE)
    )

    fun createNotification(
        context: Context,
        guardLevel: String = "0",
        titleName: String = "guardLevel",
        color: Int = android.R.color.darker_gray
    ): Notification {
        val builder =
            NotificationCompat.Builder(context, FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentIntent(
                    context.activityPendingIntent<MainActivity>(
                        MainActivity.OPEN_FROM_ANALYSIS_SERVICE,
                        ""
                    )
                )
                .setTicker("Ticker text")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setOngoing(true)

        // Set custom content view for normal and big notifications
        builder.setCustomContentView(
            FgwSeviceNotificationHandler.getNormalContentView(
                context,
                guardLevel,
                titleName,
                color
            )
        )
        builder.setCustomBigContentView(getBigContentView(context, guardLevel, titleName, color))
        tmpGuardLevel = guardLevel.toInt()
        return builder.build()
    }

    fun updateNotificationFromStoredValues(context: Context) {
        val notification = createNotification(context, guardLevel, titleName, color)
        val notificationManager = NotificationManagerCompat.from(context)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    fun getNormalContentView(
        context: Context,
        guardLevel: String,
        titleName: String,
        color: Int
    ): RemoteViews {
        val remoteViews = RemoteViews(context.packageName, R.layout.fgw_notification_normal)

        remoteViews.setTextViewText(R.id.tv_status, guardLevel)
        remoteViews.setInt(R.id.tv_status, "setBackgroundColor", color)
        remoteViews.setTextViewText(R.id.tv_title, titleName)

        val buttonActions = if (isScreenLocked(context)) {
            if (isChangingGuardLevel) {
                normalLytLevelChangingBtns
            } else {
                normalLytLevelBtns.map { Triple(it.first, it.second, it.third) }.toMutableList().also {
                    if (!canChangeLevel) {
                        it[2] = Triple(it[2].first, R.drawable.baseline_lock_24, it[2].third)
                    }
                }
            }
        } else {
            normalLytEntryBtns
        }

        remoteViews.setGroupBtns(context, buttonActions, canChangeLevel, isLevelGroup,levelButtonResId)
        return remoteViews
    }

    private fun getBigContentView(
        context: Context,
        guardLevel: String,
        titleName: String,
        color: Int
    ): RemoteViews {
        val remoteViews = RemoteViews(context.packageName, R.layout.fgw_notification_big)

        remoteViews.setTextViewText(R.id.tv_status, guardLevel)
        remoteViews.setInt(R.id.tv_status, "setBackgroundColor", color)
        remoteViews.setTextViewText(R.id.tv_title, titleName)

        val buttonActions = if (!isLevelGroup) {
            bigLytEntryBtns
        } else {
            if (isChangingGuardLevel) {
                bigLytLevelBtnsChanging
            } else {
                bigLytLevelBtns.map { Triple(it.first, it.second, it.third) }.toMutableList().also {
                    if (!canChangeLevel) {
                        it[3] = Triple(it[3].first, R.drawable.baseline_lock_24, it[3].third)
                    }
                }
            }
        }

        remoteViews.setGroupBtns(context, buttonActions, canChangeLevel, isLevelGroup, levelButtonResId)
        return remoteViews
    }

    private fun isScreenLocked(context: Context): Boolean {
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }
}
