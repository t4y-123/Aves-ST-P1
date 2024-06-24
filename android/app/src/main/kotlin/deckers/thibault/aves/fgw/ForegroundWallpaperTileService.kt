package deckers.thibault.aves
import android.content.Intent
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import android.content.Context
import android.content.BroadcastReceiver
import android.content.IntentFilter;
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.fgw.FgwIntentAction

class ForegroundWallpaperTileService : TileService() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            when (intent?.action) {
                FgwIntentAction.ACTION_FGW_TILE_SERIVCE_START -> qsTile?.run {
                    state = Tile.STATE_ACTIVE
                    isTileClickRuning = true
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
            ForegroundWallpaperService.stop(this)
            tile.state = Tile.STATE_INACTIVE
            isTileClickRuning = false
            Log.d(LOG_TAG, "Service stopped, tile state : ${tile.state} isTileClickRuning $isTileClickRuning")
        } else {
            ForegroundWallpaperService.startForeground(this)
            tile.state = Tile.STATE_ACTIVE
            isTileClickRuning = true
            Log.d(LOG_TAG, "Service started, tile state: ${tile.state}  isTileClickRuning $isTileClickRuning")
        }

        tile.updateTile()
    }

    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile
        Log.d(LOG_TAG, "onStartListening, tile state: ${tile.state} isTileClickRuning:$isTileClickRuning")
        // don't set the tile service as recommend  active mode in offical:
        // https://developer.android.com/develop/ui/views/quicksettings-tiles
        // for every time will start the service is quiet more fit my need.
        if (isTileClickRuning) {
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
        var isTileClickRuning = true
    }
}
