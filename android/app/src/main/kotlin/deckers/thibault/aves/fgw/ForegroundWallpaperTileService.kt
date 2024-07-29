package deckers.thibault.aves

import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import android.content.Context
import android.content.SharedPreferences
import android.content.IntentFilter;
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.utils.startService
import deckers.thibault.aves.fgw.*
import android.os.Build
import android.annotation.SuppressLint

class ForegroundWallpaperTileService : TileService() {
    private var tileServiceContext = this

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            when (intent?.action) {
                FgwIntentAction.TILE_SERIVCE_START -> qsTile?.run {
                    state = Tile.STATE_ACTIVE
                    updateTile()
                }
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "onStartCommand  current state: ${qsTile.state}",e)
        }
        setIsTileClickRunning(this,true)
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onClick() {
        super.onClick()
        val tile = qsTile
        Log.d(LOG_TAG, "Tile clicked, current state: ${tile.state}")

        if (tile.state == Tile.STATE_ACTIVE) {
            WallpaperScheduleHelper.cancelFgwServiceRelateSchedule(tileServiceContext)
            ForegroundWallpaperService.stop(tileServiceContext)
            tile.state = Tile.STATE_INACTIVE
            setIsTileClickRunning(this, false)
            Log.d(LOG_TAG, "Service stopped, tile state: ${tile.state} isTileClickRunning ${getIsTileClickRunning(this)}")
        } else {
            ForegroundWallpaperService.startForeground(tileServiceContext)
            tile.state = Tile.STATE_ACTIVE
            setIsTileClickRunning(tileServiceContext, true)
            Log.d(LOG_TAG, "Service started, tile state: ${tile.state} isTileClickRunning true")
        }
        tile.updateTile()
    }

    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile
        Log.d(LOG_TAG, "onStartListening, tile state: ${tile.state} isTileClickRuning:${getIsTileClickRunning(this)}")
        // don't set the tile service as recommend  active mode in offical:
        // https://developer.android.com/develop/ui/views/quicksettings-tiles
        // for every time will start the service is quiet more fit my need.

        if (tile.state == Tile.STATE_UNAVAILABLE) {
            ForegroundWallpaperService.stop(this)
            tile.state = Tile.STATE_INACTIVE
            Log.d(LOG_TAG, "Tile unavailable, stopping service and setting tile state to inactive")
        } 
        if (getIsTileClickRunning(this)) {
            ForegroundWallpaperService.startForeground(this)
            tile.state = Tile.STATE_ACTIVE
            Log.d(LOG_TAG, "Service started, tile state: ${tile.state}")
        }
        if(tile.state == Tile.STATE_UNAVAILABLE){
            tile.state = Tile.STATE_ACTIVE
        }
        tile.updateTile()
        Log.d(LOG_TAG, "Tile started listening, current state: ${tile.state}")
    }

    override fun onStopListening() {
        super.onStopListening()
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ForegroundWallpaperTileService>()
        // use is clickRuning to make the tile determine whether start service every time drap the  Quick Settings panel
        //default need to be true
        //var isTileClickRuning = true
        private const val PREF_NAME = "ForegroundWallpaperTilePrefs"
        private const val PREF_IS_TILE_CLICK_RUNNING = "isTileClickRunning"

        private fun getSharedPreferences(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        }

        fun getIsTileClickRunning(context: Context): Boolean {
            return getSharedPreferences(context).getBoolean(PREF_IS_TILE_CLICK_RUNNING, true)
        }

        fun setIsTileClickRunning(context: Context, isRunning: Boolean) {
            getSharedPreferences(context).edit().putBoolean(PREF_IS_TILE_CLICK_RUNNING, isRunning).apply()
        }

        fun updateFgwSchedules(context: Context){
            Log.d(LOG_TAG, "updateFgwSchedules in ForegroundWallpaperService : as getIsTileClickRunning:" +
                    "[${getIsTileClickRunning(context)}]")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                kotlin.runCatching {
                    context.startService<ForegroundWallpaperService> {
                        action = FgwIntentAction.SYNC_FGW_SCHEDULE_CHANGES
                    }
                }
            }
        }

        @SuppressLint("ObsoleteSdkInt")
        fun upTile(context: Context,active: Boolean) {
            Log.d(LOG_TAG, "Foreground wallpaper upTile in ForegroundWallpaperService : $active")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                kotlin.runCatching {
                    context.startService<ForegroundWallpaperTileService> {
                        action = if (active) {
                            FgwIntentAction.TILE_SERIVCE_START
                        } else {
                            FgwIntentAction.TILE_SERIVCE_STOP
                        }
                    }
                }

            }
        }
    }
}
