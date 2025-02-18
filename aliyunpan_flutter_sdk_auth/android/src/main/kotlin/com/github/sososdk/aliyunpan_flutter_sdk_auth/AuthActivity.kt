package com.github.sososdk.aliyunpan_flutter_sdk_auth

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.github.sososdk.aliyunpan_flutter_sdk_auth.utils.startFlutterActivity

class AuthActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startFlutterActivity(intent)
        finish()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        startFlutterActivity(intent)
        finish()
    }
}