package deckers.thibault.aves

import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import android.content.Context
import android.content.BroadcastReceiver
import android.content.IntentFilter;
import deckers.thibault.aves.utils.LogUtils


class ForegroundWallpaperTileService : TileService() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            when (intent?.action) {
                ACTION_START_FGW_TILE_SERIVCE -> qsTile?.run {
                    state = Tile.STATE_ACTIVE
                    updateTile()
                }
            }
        } catch (e: Exception) {
            Log.e(LOG_TAG, "onStartCommand  current state: ${qsTile.state}",e)
        }
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onClick() {
        super.onClick()
        val tile = qsTile
        Log.d(LOG_TAG, "Tile clicked, current state: ${tile.state}")

        if (tile.state == Tile.STATE_ACTIVE) {
            stopForegroundService()
            tile.state = Tile.STATE_INACTIVE
            Log.d(LOG_TAG, "Service stopped, tile state: ${tile.state}")
        } else {
            startForegroundService()
            tile.state = Tile.STATE_ACTIVE
            Log.d(LOG_TAG, "Service started, tile state: ${tile.state}")
        }

        tile.updateTile()
    }

    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile
        // don't set the tile service as recommend  active mode in offical:
        // https://developer.android.com/develop/ui/views/quicksettings-tiles
        // for every time will start the service is quiet more fit my need.
        if (tile.state == Tile.STATE_ACTIVE) {
            startForegroundService()
            Log.d(LOG_TAG, "startForegroundService tile state: ${tile.state} tile.state == Tile.STATE_ACTIVE")
        }
        Log.d(LOG_TAG, "Tile started listening, current state: ${tile.state}")
    }

    override fun onStopListening() {
        super.onStopListening()
    }

    private fun startForegroundService() {
        val intent = Intent(this, ForegroundWallpaperService::class.java)
        startService(intent)
        Log.d(LOG_TAG, "Foreground service start intent sent")
    }

    private fun stopForegroundService() {
        val intent = Intent(this, ForegroundWallpaperService::class.java)
        stopService(intent)
        Log.d(LOG_TAG, "Foreground service stop intent sent")
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ForegroundWallpaperTileService>()
        const val ACTION_START_FGW_TILE_SERIVCE = "ACTION_START_FGW_TILE_SERIVCE"
    }
}
