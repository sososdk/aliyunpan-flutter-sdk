package com.github.sososdk.aliyunpan_flutter_sdk_auth

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import com.github.sososdk.aliyunpan_flutter_sdk_auth.utils.getAliyunpanCallbackIntent

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** AliyunpanFlutterSdkAuthPlugin */
class AliyunpanFlutterSdkAuthPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
    private lateinit var activityPluginBinding: ActivityPluginBinding

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.github.sososdk/aliyunpan_flutter_sdk_auth")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isAppInstalled" -> {
                result.success(isAliyunpanAppInstalled())
            }

            "requestAuthcode" -> {
                try {
                    startRedirectUri(call.arguments<String>()!!)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityPluginBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityPluginBinding.removeOnNewIntentListener(this)
    }

    override fun onNewIntent(intent: Intent): Boolean {
        return intent.getAliyunpanCallbackIntent()?.let {
            channel.invokeMethod("onAuthcode", mapOf("error" to it.getStringExtra("error"), "code" to it.getStringExtra("code")))
            true
        } ?: run {
            false
        }
    }

    private fun isAliyunpanAppInstalled(): Boolean {
        val packageManager = activityPluginBinding.activity.packageManager
        return try {
            packageManager.getPackageInfo("com.alicloud.databox", 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun startRedirectUri(redirectUri: String) {
        Intent(Intent.ACTION_VIEW, Uri.parse(redirectUri)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK).let {
            activityPluginBinding.activity.startActivity(it)
        }
    }
}
