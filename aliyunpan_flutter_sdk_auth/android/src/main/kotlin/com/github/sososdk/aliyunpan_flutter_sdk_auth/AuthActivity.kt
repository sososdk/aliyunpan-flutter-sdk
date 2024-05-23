package com.github.sososdk.aliyunpan_flutter_sdk_auth

import android.app.Activity
import android.os.Bundle
import com.github.sososdk.aliyunpan_flutter_sdk_auth.utils.startFlutterActivity

class AuthActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startFlutterActivity(intent)
    }
}