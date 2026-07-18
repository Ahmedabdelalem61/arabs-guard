package com.arabsguard.arabs_guard

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.VpnService
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address

class MainActivity : FlutterActivity() {
    private var pendingVpnResult: MethodChannel.Result? = null
    private var pendingRouterResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> prepareVpn(result)
                "startVpn" -> startVpn(result)
                "vpnStatus" -> result.success(GuardVpnService.isRunning)
                "detectRouterGateway" -> detectRouterGateway(result)
                "openVpnSettings" -> {
                    startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
                    result.success(null)
                }
                "configureRouter" -> {
                    val address = call.argument<String>("address")?.trim().orEmpty()
                    val username = call.argument<String>("username").orEmpty()
                    val password = call.argument<String>("password").orEmpty()
                    if (address.isBlank() || username.isBlank() || password.isBlank()) {
                        result.error("missing_credentials", "Router address and credentials are required.", null)
                    } else if (pendingRouterResult != null) {
                        result.error("setup_busy", "A router setup is already running.", null)
                    } else {
                        pendingRouterResult = result
                        startActivityForResult(
                            Intent(this, RouterAutomationActivity::class.java).apply {
                                putExtra(RouterAutomationActivity.EXTRA_ADDRESS, address)
                                putExtra(RouterAutomationActivity.EXTRA_USERNAME, username)
                                putExtra(RouterAutomationActivity.EXTRA_PASSWORD, password)
                            },
                            REQUEST_ROUTER,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun prepareVpn(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent == null) {
            result.success(true)
            return
        }
        if (pendingVpnResult != null) {
            result.error("vpn_busy", "The Android VPN consent dialog is already open.", null)
            return
        }
        pendingVpnResult = result
        startActivityForResult(intent, REQUEST_VPN)
    }

    private fun detectRouterGateway(result: MethodChannel.Result) {
        val connectivity = getSystemService(ConnectivityManager::class.java)
        val network = connectivity.activeNetwork
        val capabilities = network?.let(connectivity::getNetworkCapabilities)
        val onLocalNetwork = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true ||
            capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true
        if (!onLocalNetwork) {
            result.success(null)
            return
        }
        val gateway = connectivity.getLinkProperties(network)
            ?.routes
            ?.firstOrNull { route ->
                route.isDefaultRoute && route.gateway is Inet4Address
            }
            ?.gateway
            ?.hostAddress
        result.success(gateway)
    }

    private fun startVpn(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
        }
        ContextCompat.startForegroundService(
            this,
            Intent(this, GuardVpnService::class.java).setAction(GuardVpnService.ACTION_START),
        )
        result.success(true)
    }

    @Deprecated("Deprecated in Android; retained for Flutter embedding compatibility.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_VPN -> {
                pendingVpnResult?.success(resultCode == Activity.RESULT_OK)
                pendingVpnResult = null
            }
            REQUEST_ROUTER -> {
                val payload = hashMapOf<String, Any>(
                    "ok" to (resultCode == Activity.RESULT_OK && data?.getBooleanExtra("ok", false) == true),
                    "model" to (data?.getStringExtra("model") ?: "Unknown router"),
                    "message" to (data?.getStringExtra("message") ?: "Router setup was cancelled."),
                    "workflow" to (data?.getStringExtra("workflow") ?: "unknown"),
                )
                pendingRouterResult?.success(payload)
                pendingRouterResult = null
            }
        }
    }

    companion object {
        private const val CHANNEL = "com.arabsguard.guard/control"
        private const val REQUEST_VPN = 4101
        private const val REQUEST_ROUTER = 4102
        private const val REQUEST_NOTIFICATIONS = 4103
    }
}
