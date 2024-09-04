package deckers.thibault.aves.fgw
import android.content.Context

@Suppress("ConstPropertyName")
object FgwIntentAction {
    // handler to start or stop intent
    const val START_FGW_SERVICE = "FGW_START_SERVICE"
    const val STOP_FGW_SERVICE = "FGW_STOP_SERVICE"
    //service notifcation intent
    const val SERVICE_STATE_CHANGED = "FGW_SERVICE_STATE_CHANGED"
    const val SWITCH_GROUP = "FGW_SWITCH_GROUP"
    const val PRE = "FGW_PRE"
    const val NEXT = "FGW_NEXT"
    const val DUPLICATE = "FGW_DUPLICATE"
    const val USED_RECORD = "fgw_used_entry_record_open"
    const val DOWNWARD = "FGW_DOWNWARD"
    const val UPWARD = "FGW_UPWARD"
    const val LOCK = "FGW_LOCK"
    const val UNLOCK = "FGW_UNLOCK"
    const val APPLY_LEVEL_CHANGE = "FGW_APPLY_LEVEL_CHANGE"
    const val CANCEL_LEVEL_CHANGE = "FGW_CANCEL_LEVEL_CHANGE"
    const val SYNC_FGW_SCHEDULE_CHANGES = "syncFgwScheduleChanges"
    //tile service
    const val TILE_SERIVCE_START = "FGW_TILE_SERIVCE_START"
    const val TILE_SERIVCE_STOP = "FGW_TILE_SERIVCE_STOP"
}

@Suppress("ConstPropertyName")
object FgwConstant {
    const val CUR_TYPE_HOME = "home"
    const val CUR_TYPE_LOCK = "lock"
    const val CUR_TYPE_BOTH = "both"
    const val CUR_TYPE_WIDGET = "widget"
    const val NOT_WIDGET_ID:Int = 0
    const val FGW_VIEW_OPEN = "fgw_view_open"
    // for both will be used in flutter side, so use Camelcase not Snakecase。
    //dart helpl start or stop
    const val START = "start"
    const val STOP = "stop"
    //wallpaper op string
    const val FGW_UPDATE_TYPE_EXTRA = "updateType"
    const val FGW_WIDGET_ID_EXTRA = "widgetId"
    //wallpaper op string
    const val NEXT_WARLLPAPER = "nextWallpaper"
    const val PRE_WARLLPAPER = "preWallpaper"
    const val CHANGE_GUARD_LEVEL = "changeGuardLevel"
    const val newGuardLevel = "newGuardLevel"
    // for sync data
    const val CUR_LEVEL = "curLevel"
    const val ACTIVE_LEVELS = "activeLevels"
    const val SCHEDULES = "schedules"
    const val CUR_ENTRY_NAME = "curEntryName"
    const val GUARD_LEVEL_LOCK = "guardLevelLock"

    //sync data from Native side.
    const val SYNC_FGW_SCHEDULE_CHANGES = "syncFgwScheduleChanges"
    const val FGW_LOCK = "fgwLock"
    const val FGW_UNLOCK = "fgw_unlock"

    // Use diff key with the package name prefix to diff in debug apk or release or flavor apk.

    const val home_schedule_key = "home-0"
    const val lock_schedule_key = "lock-0"
    const val both_schedule_key = "both-0"



    fun getScheduleKey(context: Context, baseKey: String): String {
        val packageName = context.packageName
        return "$packageName-$baseKey"
    }

    fun getHomeScheduleKey(context: Context) = getScheduleKey(context, "home-0")
    fun getLockScheduleKey(context: Context) = getScheduleKey(context, "lock-0")
    fun getBothScheduleKey(context: Context) = getScheduleKey(context, "both-0")
}

// Data classes to represent the complex objects
data class FgwGuardLevelRow(val id: Int, val level: Int, val name: String, val color: Int,val isActive: Boolean)
data class WallpaperScheduleRow(
    val id: Int, val order: Int, val labelName: String, val guardLevelId: Int, val filtersSetId: Int,
    val updateType: String, val widgetId: Int,val displayType:String, val interval: Int, val isActive: Boolean
)