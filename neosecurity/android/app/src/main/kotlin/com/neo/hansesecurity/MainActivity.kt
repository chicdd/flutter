package com.neo.neosecurity


import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.neo.config/channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppName" -> {
                        // manifestPlaceholders["appName"] 값은 BuildConfig로 접근 가능
                        // Gradle에서 manifestPlaceholders는 BuildConfig로 자동 생성되지 않으므로
                        // 아래처럼 직접 정의하거나, gradle task로 BuildConfig에 넣어야 함
                        result.success(BuildConfig.APP_NAME)
                    }
                    "getGaetongCode" -> {
                        result.success(BuildConfig.GAETONG_CODE)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}