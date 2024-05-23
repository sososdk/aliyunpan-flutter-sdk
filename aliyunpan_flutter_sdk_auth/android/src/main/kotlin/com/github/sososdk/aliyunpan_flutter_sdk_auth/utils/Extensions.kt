package com.github.sososdk.aliyunpan_flutter_sdk_auth.utils

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.github.sososdk.aliyunpan_flutter_sdk_auth.PluginConfig

internal const val KEY_ALIYUNPAN_EXTRA = "KEY_ALIYUNPAN_EXTRA"
internal const val FLAG_PAYLOAD_FROM_ALIYUNPAN = "FLAG_PAYLOAD_FROM_ALIYUNPAN"

internal fun Activity.startFlutterActivity(
    extra: Intent,
) {
    flutterActivityIntent()?.also { intent ->
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        intent.putExtra(KEY_ALIYUNPAN_EXTRA, extra)
        intent.putExtra(FLAG_PAYLOAD_FROM_ALIYUNPAN, true)
        try {
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Log.w("aliyunpan", "Can not start activity for Intent: $intent")
        }
    }
}

internal fun Context.flutterActivityIntent(): Intent? {
    return if (PluginConfig.flutterActivity.isBlank()) {
        packageManager.getLaunchIntentForPackage(packageName)
    } else {
        Intent().also {
            it.setClassName(this, "${packageName}.${PluginConfig.flutterActivity}")
        }
    }
}

internal fun Intent.getAliyunpanCallbackIntent(): Intent? {
    return if (getBooleanExtra(FLAG_PAYLOAD_FROM_ALIYUNPAN, false)) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getParcelableExtra(KEY_ALIYUNPAN_EXTRA, Intent::class.java)
        } else {
            getParcelableExtra(KEY_ALIYUNPAN_EXTRA)
        }
    } else {
        null
    }
}
