package deckers.thibault.aves

import android.annotation.SuppressLint
import android.app.Service
import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.os.IBinder
import android.content.pm.ServiceInfo
import android.widget.Toast;
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import android.app.KeyguardManager
import android.graphics.Color
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.ForegroundInfo
import androidx.core.content.ContextCompat
import app.loup.streams_channel.StreamsChannel
import kotlinx.coroutines.*
import deckers.thibault.aves.utils.LogUtils
import deckers.thibault.aves.utils.startForegroundServiceCompat
import deckers.thibault.aves.utils.startService
import deckers.thibault.aves.utils.stopService
import deckers.thibault.aves.utils.servicePendingIntent
import deckers.thibault.aves.utils.activityPendingIntent
import deckers.thibault.aves.fgw.FgwIntentAction
import deckers.thibault.aves.channel.calls.DeviceHandler
import deckers.thibault.aves.channel.calls.MediaStoreHandler
import deckers.thibault.aves.channel.calls.MediaFetchObjectHandler
import deckers.thibault.aves.channel.calls.MediaFetchBytesHandler
import deckers.thibault.aves.channel.calls.StorageHandler
import deckers.thibault.aves.channel.streams.ImageByteStreamHandler
import deckers.thibault.aves.channel.streams.MediaStoreStreamHandler
import deckers.thibault.aves.channel.AvesByteSendingMethodCodec
import deckers.thibault.aves.model.FieldMap
import deckers.thibault.aves.utils.FlutterUtils
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.runBlocking
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

import deckers.thibault.aves.channel.calls.MetadataFetchHandler
import deckers.thibault.aves.channel.calls.GeocodingHandler

class ForegroundWallpaperService : Service() {

    private val defaultScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private lateinit var screenStateReceiver: BroadcastReceiver


    override fun onCreate() {
        super.onCreate()
createNotificationChannel()
        startForeground(2, createNotification())
        registerScreenStateReceiver()
        isRunning = true
        upTile(true)
        Log.i(LOG_TAG, "Foreground wallpaper service started")
    }

    @SuppressLint("ObsoleteSdkInt")
    private fun upTile(active: Boolean) {
        Log.d(LOG_TAG, "Foreground wallpaper upTile in ForegroundWallpaperService : $active")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            kotlin.runCatching {
                startService<ForegroundWallpaperTileService> {
                    action = if (active) {
                        FgwIntentAction.ACTION_FGW_TILE_SERIVCE_START
                    } else {
                        FgwIntentAction.ACTION_FGW_TILE_SERIVCE_STOP
                    }
                }
            }

        }
    }

    private fun createNotification(
        guardLevel: String = "0",
        titleName: String = "guardLevel",
        color: Int = android.R.color.darker_gray
    ): Notification {
        val builder = NotificationCompat.Builder(this, FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(
                activityPendingIntent<MainActivity>(
                    MainActivity.OPEN_FROM_ANALYSIS_SERVICE,
                    ""
                )
            )
            .setTicker("Ticker text")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setOngoing(true)

        // Set custom content view for normal and big notifications
        builder.setCustomContentView(getNormalContentView(guardLevel, titleName, color))
        builder.setCustomBigContentView(getBigContentView(guardLevel, titleName, color))

        return builder.build()
    }

    private fun parseColorString(colorString: String?): Int? {
        if (colorString == null) return null

        // Example colorString format: "Color(0xff808080)"
        val regex = Regex("^Color\\(0x([0-9a-fA-F]+)\\)\$")
        val matchResult = regex.find(colorString) ?: return null

        return try {
            val hexColor = matchResult.groupValues[1]
            val alpha = hexColor.substring(0, 2).toInt(16) // Alpha component
            val red = hexColor.substring(2, 4).toInt(16) // Red component
            val green = hexColor.substring(4, 6).toInt(16) // Green component
            val blue = hexColor.substring(6, 8).toInt(16) // Blue component

            // Combine components into ARGB color format (alpha in highest byte)
            (alpha shl 24) or (red shl 16) or (green shl 8) or blue
        } catch (e: NumberFormatException) {
            e.printStackTrace()
            null
        }
    }

    private fun updateNotification(
        context: Context,
        props: FieldMap?,
    ) {
        Log.d(LOG_TAG, "updateNotification : $context $props")
        props ?: return
        var guardLevel = props["guardLevel"] as String? // ?: "0
        var titleName = props["titleName"] as String? //?: "Guard Level"

        var colorString = props["color"] as String? //?: android.R.color.darker_gray
        var colorValue = 1
        if (colorString != null) {
            colorValue = parseColorString(colorString) ?: 0
       }
        if (guardLevel == null) {
            guardLevel = "0"
        }
        if (titleName == null) {
            titleName = "Guard Level"
         }
        if (colorValue == null) {
            colorValue = android.R.color.darker_gray
        }

        val notification = createNotification(guardLevel, titleName, colorValue)
        val notificationManager = NotificationManagerCompat.from(applicationContext)
        notificationManager.notify(NOTIFICATION_ID, notification)
     }

    private suspend fun getUpdateNotificationProps(
        context: Context,
    ): FieldMap? {
        Log.d(LOG_TAG, "start to getUpdateNotificationProps")
        initFlutterEngine(context)
        val messenger = flutterEngine!!.dartExecutor
        val channel = MethodChannel(messenger, FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL)
        try {
            val props = suspendCoroutine<Any?> { cont ->
                defaultScope.launch {
                    FlutterUtils.runOnUiThread {
                        channel?.invokeMethod("updateNotificationProp", null, object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                Log.d(LOG_TAG, " getUpdateNotificationProps result:$result")
                                cont.resume(result)
                            }

                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                cont.resumeWithException(Exception("$errorCode: $errorMessage\n$errorDetails"))
                            }

                            override fun notImplemented() {
                                cont.resumeWithException(Exception("not implemented"))
                            }
                        })
                    }
                }
            }
            @Suppress("unchecked_cast")
            return props as FieldMap?
        } catch (e: Exception) {
            Log.e(LOG_TAG, "failed to getUpdateNotificationProps", e)
        }
        return null
    }

    private fun updateNotificationFromDart() {
        defaultScope.launch {
            val props = getUpdateNotificationProps(applicationContext)
            Log.d(LOG_TAG, "fupdateNotificationFromDart  $props")
            //val color = Color.parseColor("#${Integer.toHexString(colorValue)}")
            delay(500)
            Log.d(LOG_TAG, "   delay(500):  $props")
            updateNotification(applicationContext,props)
        }
    }

    private fun getNormalContentView(
        guardLevel: String,
        titleName: String,
        color: Int
    ): RemoteViews {
        val remoteViews = RemoteViews(packageName, R.layout.fgw_notification_normal)

        remoteViews.setTextViewText(R.id.tv_status, guardLevel)
        remoteViews.setInt(R.id.tv_status, "setBackgroundColor", color)
        remoteViews.setTextViewText(R.id.tv_title, titleName)
        // Set button images and click actions based on screen lock status
        setupButton(
            remoteViews,
            R.id.iv_normal_layout_button_01,
            FgwIntentAction.ACTION_LEFT,
            R.drawable.baseline_navigate_before_24
        )
        setupButton(
            remoteViews,
            R.id.iv_normal_layout_button_02,
            FgwIntentAction.ACTION_RIGHT,
            R.drawable.baseline_navigate_next_24
        )
        setupButton(
            remoteViews,
            R.id.iv_normal_layout_button_03,
            FgwIntentAction.ACTION_DUPLICATE,
            R.drawable.baseline_add_photo_alternate_24
        )
        setupButton(
            remoteViews,
            R.id.iv_normal_layout_button_04,
            FgwIntentAction.ACTION_RESHUFFLE,
            R.drawable.baseline_shuffle_24
        )

        // Set special actions and images if screen is locked
        if (isScreenLocked()) {
            setupButton(
                remoteViews,
                R.id.iv_normal_layout_button_01,
                FgwIntentAction.ACTION_DOWNWARD,
                R.drawable.baseline_arrow_downward_24
            )
            setupButton(
                remoteViews,
                R.id.iv_normal_layout_button_02,
                FgwIntentAction.ACTION_UPWARD,
                R.drawable.baseline_arrow_upward_24
            )

            if (isLocked) {
                setupButton(
                    remoteViews,
                    R.id.iv_normal_layout_button_03,
                    FgwIntentAction.ACTION_LOCK_UNLOCK,
                    R.drawable.baseline_lock_24
                )
            } else {
                setupButton(
                    remoteViews,
                    R.id.iv_normal_layout_button_03,
                    FgwIntentAction.ACTION_LOCK_UNLOCK,
                    R.drawable.baseline_lock_open_24
                )
            }

            setupButton(
                remoteViews,
                R.id.iv_normal_layout_button_04,
                FgwIntentAction.ACTION_APPLY_LEVEL_CHANGE,
                R.drawable.baseline_check_24
            )
        }

        return remoteViews
    }

    private fun getBigContentView(guardLevel: String, titleName: String, color: Int): RemoteViews {
        val remoteViews = RemoteViews(packageName, R.layout.fgw_notification_big)

        remoteViews.setTextViewText(R.id.tv_status, guardLevel)
        remoteViews.setInt(R.id.tv_status, "setBackgroundColor", color)
        remoteViews.setTextViewText(R.id.tv_title, titleName)

        // Set button images and click actions based on group status
        if (isGroup1) {
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_01,
                FgwIntentAction.ACTION_SWITCH_GROUP,
                R.drawable.baseline_menu_open_24
            )
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_02,
                FgwIntentAction.ACTION_LEFT,
                R.drawable.baseline_navigate_before_24
            )
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_03,
                FgwIntentAction.ACTION_RIGHT,
                R.drawable.baseline_navigate_next_24
            )
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_04,
                FgwIntentAction.ACTION_DUPLICATE,
                R.drawable.baseline_add_photo_alternate_24
            )
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_05,
                FgwIntentAction.ACTION_RESHUFFLE,
                R.drawable.baseline_shuffle_24
            )
        } else {
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_01,
                FgwIntentAction.ACTION_SWITCH_GROUP,
                R.drawable.baseline_menu_open_24
            )
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_02,
                FgwIntentAction.ACTION_DOWNWARD,
                R.drawable.baseline_arrow_downward_24
            )
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_03,
                FgwIntentAction.ACTION_UPWARD,
                R.drawable.baseline_arrow_upward_24
            )
            // Set lock button based on lock status
            if (isLocked) {
                setupButton(
                    remoteViews,
                    R.id.iv_big_layout_button_04,
                    FgwIntentAction.ACTION_LOCK_UNLOCK,
                    R.drawable.baseline_lock_24
                )
            } else {
                setupButton(
                    remoteViews,
                    R.id.iv_big_layout_button_04,
                    FgwIntentAction.ACTION_LOCK_UNLOCK,
                    R.drawable.baseline_lock_open_24
                )
            }
            setupButton(
                remoteViews,
                R.id.iv_big_layout_button_05,
                FgwIntentAction.ACTION_APPLY_LEVEL_CHANGE,
                R.drawable.baseline_check_24
            )
        }

        return remoteViews
    }

    private fun setupButton(
        remoteViews: RemoteViews,
        buttonId: Int,
        action: String,
        iconResId: Int
    ) {
        remoteViews.setImageViewResource(buttonId, iconResId)
        remoteViews.setOnClickPendingIntent(
            buttonId,
            servicePendingIntent<ForegroundWallpaperService>(action)
        )
    }

    // create update notification
    private fun createNotificationChannel() {
        val channel = NotificationChannelCompat.Builder(
            FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID,
            NotificationManagerCompat.IMPORTANCE_HIGH
        )
            //.setName(applicationContext.getText(R.string.analysis_channel_name))
            .setName("ForegroundWallpaper")
            .setShowBadge(false)
            .build()
        NotificationManagerCompat.from(applicationContext).createNotificationChannel(channel)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            FgwIntentAction.ACTION_SWITCH_GROUP -> {
                isGroup1 = !isGroup1
                updateNotificationFromDart()
            }

            FgwIntentAction.ACTION_LEFT -> showToast("Left arrow tapped")
            FgwIntentAction.ACTION_RIGHT -> showToast("Right arrow tapped")
            FgwIntentAction.ACTION_DUPLICATE -> showToast("Duplicate icon tapped")
            FgwIntentAction.ACTION_RESHUFFLE -> showToast("Reshuffle icon tapped")
            FgwIntentAction.ACTION_DOWNWARD -> showToast("Downward arrow tapped")
            FgwIntentAction.ACTION_UPWARD -> showToast("Upward arrow tapped")
            FgwIntentAction.ACTION_APPLY_LEVEL_CHANGE -> showToast("APPLY LEVEL CHANGE")
            FgwIntentAction.ACTION_LOCK_UNLOCK -> {
                isLocked = !isLocked
                showToast(if (isLocked) "Locked" else "Unlocked")
                updateNotificationFromDart()
            }

            Intent.ACTION_SCREEN_ON -> handleScreenOn()
            Intent.ACTION_SCREEN_OFF -> handleScreenOff()
            Intent.ACTION_USER_PRESENT -> handleUserPresent()
        }
        return START_STICKY
    }

    private fun handleScreenOn() {
        // Handle screen on event
        Log.i(LOG_TAG, "Screen ON")
        updateNotificationFromDart()
    }

    private fun handleScreenOff() {
        // Handle screen off event
        Log.i(LOG_TAG, "Screen OFF")
        updateNotificationFromDart()
    }

    private fun handleUserPresent() {
        // Handle user present (unlock) event
        Log.i(LOG_TAG, "User Present (Unlocked)")
        updateNotificationFromDart()
    }

    private fun handleStartService() {
        // Handle starting the service
        Log.i(LOG_TAG, "Service started")
        updateNotificationFromDart()
    }


    // create and update notification end
    private fun isScreenLocked(): Boolean {
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return keyguardManager.isKeyguardLocked
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(LOG_TAG, "Clean foreground wallpaper flutterEngine")
        // Unregister receiver for screen events
        unregisterScreenStateReceiver()
        isRunning = false
    }


    // Functionality of register and unregister for screen on, screen off, and screen unlock intents
    // when starting or stopping the service
    private fun registerScreenStateReceiver() {
        screenStateReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON -> handleScreenOn()
                    Intent.ACTION_SCREEN_OFF -> handleScreenOff()
                    Intent.ACTION_USER_PRESENT -> handleUserPresent()
                    //Intent.ACTION_TIME_CHANGED -> handleUserPresent()
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenStateReceiver, filter)
    }

    private fun unregisterScreenStateReceiver() {
        try {
            unregisterReceiver(screenStateReceiver)
        } catch (e: IllegalArgumentException) {
            Log.e(LOG_TAG, "Screen state receiver not registered", e)
        }
    }

    private fun showToast(message: String) {
        Toast.makeText(applicationContext, message, Toast.LENGTH_SHORT).show()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    companion object {
        private val LOG_TAG = LogUtils.createTag<ForegroundWallpaperService>()
        const val FOREGROUND_WALLPAPER_NOTIFICATION_CHANNEL_ID = "foreground_wallpaper"
        const val NOTIFICATION_ID = 2

        var isGroup1 = true
        var isLocked = false
        var isRunning = false

        fun start(context: Context) {
            context.startService<ForegroundWallpaperService>()
        }

        fun startForeground(context: Context) {
            val intent = Intent(context, ForegroundWallpaperService::class.java)
            context.startForegroundServiceCompat(intent)
        }

        fun stop(context: Context) {
            context.stopService<ForegroundWallpaperService>()
        }

        // for dart side code
        private const val FOREGROUND_WALLPAPER_NOTIFICATION_SERVICE_CHANNEL =
            "deckers.thibault/aves/foreground_wallpaper_notification_service"
        private const val FOREGROUND_WALLPAPER_SERVICE_DART_ENTRYPOINT = "fgwNotificationService"

        private var flutterEngine: FlutterEngine? = null
        private var imageByteFetchJob: Job? = null

        private suspend fun initFlutterEngine(context: Context) {
            if (flutterEngine != null) return

            FlutterUtils.runOnUiThread {
                flutterEngine = FlutterEngine(context.applicationContext)
            }
            initChannels(context)

            flutterEngine!!.apply {
                if (!dartExecutor.isExecutingDart) {
                    val appBundlePathOverride = FlutterInjector.instance().flutterLoader().findAppBundlePath()
                    val entrypoint = DartExecutor.DartEntrypoint(appBundlePathOverride, FOREGROUND_WALLPAPER_SERVICE_DART_ENTRYPOINT)
                    FlutterUtils.runOnUiThread {
                        dartExecutor.executeDartEntrypoint(entrypoint)
                    }
                }
            }
        }

        private fun initChannels(context: Context) {
            val engine = flutterEngine
            engine ?: throw Exception("Flutter engine is not initialized")

            val messenger = engine.dartExecutor

            // dart -> platform -> dart
            // - need Context
            MethodChannel(messenger, DeviceHandler.CHANNEL).setMethodCallHandler(DeviceHandler(context))
            MethodChannel(messenger, MediaStoreHandler.CHANNEL).setMethodCallHandler(MediaStoreHandler(context))
            MethodChannel(messenger, MediaFetchBytesHandler.CHANNEL, AvesByteSendingMethodCodec.INSTANCE).setMethodCallHandler(MediaFetchBytesHandler(context))
            MethodChannel(messenger, MediaFetchObjectHandler.CHANNEL).setMethodCallHandler(MediaFetchObjectHandler(context))
            MethodChannel(messenger, StorageHandler.CHANNEL).setMethodCallHandler(StorageHandler(context))

            // result streaming: dart -> platform ->->-> dart
            // - need Context
            StreamsChannel(messenger, ImageByteStreamHandler.CHANNEL).setStreamHandlerFactory { args -> ImageByteStreamHandler(context, args) }
            StreamsChannel(messenger, MediaStoreStreamHandler.CHANNEL).setStreamHandlerFactory { args -> MediaStoreStreamHandler(context, args) }
        }
    }
}
