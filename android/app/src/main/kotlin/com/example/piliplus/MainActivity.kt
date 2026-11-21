package com.example.piliplus

import android.content.Intent
import android.content.ComponentName
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.view.WindowManager.LayoutParams
import com.ryanheise.audioservice.AudioService
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : AudioServiceActivity() {
    private var lifecycleChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        lifecycleChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "piliplus/lifecycle",
        )
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "piliplus/install",
        ).setMethodCallHandler { call, result ->
            if (call.method == "installApk") {
                val filePath = call.argument<String>("filePath")
                if (filePath.isNullOrEmpty()) {
                    result.error("INVALID_PATH", "APK file path is empty", null)
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                    !packageManager.canRequestPackageInstalls()
                ) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:$packageName"),
                    ).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(false)
                    return@setMethodCallHandler
                }
                val file = File(filePath)
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "APK file not found", null)
                    return@setMethodCallHandler
                }
                val uri = FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file,
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(intent)
                result.success(true)
} else if (call.method == "setAppIcon") {
val alias = call.argument<String>("alias") ?: "LauncherDefault"
val aliases = listOf(
"LauncherDefault",
"LauncherSlate",
"LauncherCoral",
"LauncherCeramic",
"LauncherOled",
)
if (!aliases.contains(alias)) {
result.error("INVALID_ALIAS", "Unknown icon alias", null)
return@setMethodCallHandler
}
for (name in aliases) {
val state = if (name == alias) {
PackageManager.COMPONENT_ENABLED_STATE_ENABLED
} else {
PackageManager.COMPONENT_ENABLED_STATE_DISABLED
}
packageManager.setComponentEnabledSetting(
ComponentName(this@MainActivity, "$packageName.$name"),
state,
PackageManager.DONT_KILL_APP,
)
}
result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (AndroidHelper.isFoldable) {
            AndroidHelper.ToDart.onConfigurationChanged?.run()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        AndroidHelper.ToDart.onUserLeaveHint?.run()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration?,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        AndroidHelper.isPipMode = isInPictureInPictureMode
    }

    override fun onDestroy() {
        if (!isChangingConfigurations) {
            lifecycleChannel?.invokeMethod("onDestroy", null)
            stopService(Intent(this, AudioService::class.java))
        }
        super.onDestroy()
    }
}
