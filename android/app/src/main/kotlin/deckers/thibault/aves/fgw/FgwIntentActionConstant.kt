package deckers.thibault.aves.fgw

@Suppress("ConstPropertyName")
object FgwIntentAction {
    // handler to start or stop intent
    const val START_FGW_SERVICE = "FGW_START_SERVICE"
    const val STOP_FGW_SERVICE = "FGW_STOP_SERVICE"
    //service notifcation intent
    const val SERVICE_STATE_CHANGED = "FGW_SERVICE_STATE_CHANGED"
    const val SWITCH_GROUP = "FGW_SWITCH_GROUP"
    const val LEFT = "FGW_LEFT"
    const val RIGHT = "FGW_RIGHT"
    const val DUPLICATE = "FGW_DUPLICATE"
    const val STORES = "FGW_STORES"
    const val DOWNWARD = "FGW_DOWNWARD"
    const val UPWARD = "FGW_UPWARD"
    const val LOCK_UNLOCK = "FGW_LOCK_UNLOCK"
    const val APPLY_LEVEL_CHANGE = "FGW_APPLY_LEVEL_CHANGE"
    const val CANCEL_LEVEL_CHANGE = "FGW_CANCEL_LEVEL_CHANGE"
    //tile service
    const val TILE_SERIVCE_START = "FGW_TILE_SERIVCE_START"
    const val TILE_SERIVCE_STOP = "FGW_TILE_SERIVCE_STOP"

}