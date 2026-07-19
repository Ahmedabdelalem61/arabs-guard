package com.arabsguard.arabs_guard

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import java.net.Inet4Address
import java.net.InetSocketAddress
import java.net.Socket
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PhysicalLocalNetworkContractTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    @Test
    fun grantedPermissionCanDiscoverAndReachPrivateGateway() {
        assertTrue("physical local-network certification requires API 37+", Build.VERSION.SDK_INT >= 37)
        assertEquals(
            "the physical probe must run only after local-network permission is granted",
            PackageManager.PERMISSION_GRANTED,
            context.checkSelfPermission(Manifest.permission.ACCESS_LOCAL_NETWORK),
        )

        val connectivity = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivity.activeNetwork
        assertNotNull("connect the physical device to the router Wi-Fi or Ethernet", network)
        val activeNetwork = network!!
        val capabilities = connectivity.getNetworkCapabilities(activeNetwork)
        assertTrue(
            "the physical device must use Wi-Fi or Ethernet for router certification",
            capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true ||
                capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true,
        )
        val gateway = connectivity.getLinkProperties(activeNetwork)
            ?.routes
            ?.firstOrNull { route -> route.isDefaultRoute && route.gateway is Inet4Address }
            ?.gateway as? Inet4Address
        assertNotNull("the active local network must expose an IPv4 default gateway", gateway)
        val privateGateway = gateway!!
        assertTrue("the default gateway must be a private IPv4 address", isPrivate(privateGateway))

        val reachable = listOf(80, 443).any { port ->
            try {
                Socket().use { socket ->
                    socket.connect(InetSocketAddress(privateGateway, port), 3_000)
                }
                true
            } catch (_: Exception) {
                false
            }
        }
        assertTrue(
            "the private gateway did not accept a credential-free TCP connection on port 80 or 443",
            reachable,
        )
    }

    private fun isPrivate(address: Inet4Address): Boolean {
        val octets = address.address.map { it.toInt() and 0xff }
        return octets[0] == 10 ||
            (octets[0] == 172 && octets[1] in 16..31) ||
            (octets[0] == 192 && octets[1] == 168)
    }
}
