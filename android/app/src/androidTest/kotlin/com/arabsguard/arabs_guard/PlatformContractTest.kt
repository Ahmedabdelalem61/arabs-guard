package com.arabsguard.arabs_guard

import android.Manifest
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PlatformContractTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext

    @Test
    fun runtimeAndPackageSdkContractIsSupported() {
        val expectedApi = instrumentation.arguments.getString("expectedApi")?.toIntOrNull()
        assertNotNull("the smoke runner must provide its expected API", expectedApi)
        assertEquals("runtime must match the selected test device", expectedApi, Build.VERSION.SDK_INT)
        assertTrue("runtime API must meet minSdk", Build.VERSION.SDK_INT >= 24)
        assertEquals(24, context.applicationInfo.minSdkVersion)
        assertEquals(37, context.applicationInfo.targetSdkVersion)
    }

    @Test
    fun mainFlutterActivityLaunchesAndResumes() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.moveToState(Lifecycle.State.RESUMED)
            scenario.onActivity { activity ->
                assertFalse(activity.isFinishing)
                assertEquals(
                    "Arabs Guard",
                    activity.applicationInfo.loadLabel(activity.packageManager).toString(),
                )
            }
        }
    }

    @Test
    fun vpnAndRouterComponentsStayLeastPrivilege() {
        val info = packageInfo()
        val vpnService = info.services.orEmpty().single {
            it.name == GuardVpnService::class.java.name
        }
        val routerActivity = info.activities.orEmpty().single {
            it.name == RouterAutomationActivity::class.java.name
        }
        val mainActivity = info.activities.orEmpty().single {
            it.name == MainActivity::class.java.name
        }

        assertFalse("VPN service must never be exported", vpnService.exported)
        assertEquals(Manifest.permission.BIND_VPN_SERVICE, vpnService.permission)
        if (Build.VERSION.SDK_INT >= 34) {
            assertTrue(
                "modern Android requires the declared special-use service type",
                vpnService.foregroundServiceType and
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE != 0,
            )
        }
        assertFalse("credential-bearing router activity must stay private", routerActivity.exported)
        assertTrue("launcher activity must remain exported", mainActivity.exported)
    }

    @Test
    fun permissionSurfaceContainsNoUnrelatedSensitiveAccess() {
        val requested = packageInfo().requestedPermissions.orEmpty().toSet()
        val required = setOf(
            Manifest.permission.INTERNET,
            Manifest.permission.ACCESS_NETWORK_STATE,
            Manifest.permission.FOREGROUND_SERVICE,
            Manifest.permission.POST_NOTIFICATIONS,
            Manifest.permission.ACCESS_LOCAL_NETWORK,
        )
        assertTrue("required permissions are missing: ${required - requested}", requested.containsAll(required))

        val forbidden = setOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.READ_CONTACTS,
            Manifest.permission.WRITE_CONTACTS,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.CALL_PHONE,
            Manifest.permission.READ_SMS,
            Manifest.permission.SEND_SMS,
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
        )
        assertTrue("unrelated sensitive permissions found: ${requested intersect forbidden}",
            requested.intersect(forbidden).isEmpty())

    }

    @Test
    fun freshInstallRequiresAndroid17LocalNetworkConsent() {
        if (Build.VERSION.SDK_INT < 37) return
        assertEquals(
            "a fresh install must not silently receive broad local-network access",
            PackageManager.PERMISSION_DENIED,
            context.checkSelfPermission(Manifest.permission.ACCESS_LOCAL_NETWORK),
        )
    }

    @Test
    fun freshInstallRequiresAndroidVpnConsent() {
        assertNotNull("a fresh install must require the Android-owned VPN consent UI", VpnService.prepare(context))
    }

    @Suppress("DEPRECATION")
    private fun packageInfo(): PackageInfo {
        val flags = PackageManager.GET_ACTIVITIES or
            PackageManager.GET_SERVICES or
            PackageManager.GET_PERMISSIONS
        return if (Build.VERSION.SDK_INT >= 33) {
            context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.PackageInfoFlags.of(flags.toLong()),
            )
        } else {
            context.packageManager.getPackageInfo(context.packageName, flags)
        }
    }
}
