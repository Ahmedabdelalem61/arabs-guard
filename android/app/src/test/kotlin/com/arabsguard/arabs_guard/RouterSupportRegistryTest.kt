package com.arabsguard.arabs_guard

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RouterSupportRegistryTest {
    @Test
    fun `every catalog family selects its dedicated workflow`() {
        val fixtures = mapOf(
            "WE Home Gateway DN8245V-56" to "huawei_dn8245v56",
            "ZTE Corporation ZXHN H188A V2" to "zte_h188a",
            "Huawei EchoLife HG8245W5-6T" to "huawei_fiber_ont",
            "Huawei 5G CPE H153-381" to "huawei_h153",
            "ZTE CAT4 Router K10" to "zte_k10",
            "ZTE MF971R LTE" to "zte_mifi",
            "ZTE ZXHN F670L fiber gateway" to "zte_fiber_ont",
            "ZTE ZXHN H168N" to "zte_legacy",
            "Huawei B315s-608 LTE CPE" to "huawei_mobile_cpe",
            "Huawei Home Gateway DG8045" to "huawei_legacy",
            "TP-Link Archer VR600" to "tplink_dsl",
            "TP-Link Archer MR600" to "tplink_mobile",
            "D-Link DSL-245GE EG_1.00b07" to "dlink_dsl",
            "Nokia WiFi Beacon B1.1" to "nokia_home",
            "Tenda V12 AC1200" to "tenda_dsl",
            "ASUS DSL-AC68U" to "asus_dsl",
            "NETGEAR D7000" to "netgear_dsl",
            "Technicolor TG589vn" to "technicolor_gateway",
        )

        fixtures.forEach { (fingerprint, expectedWorkflow) ->
            assertEquals(expectedWorkflow, RouterSupportRegistry.detect(fingerprint).workflowId)
        }
    }

    @Test
    fun `only exact validated firmware enables automatic writes`() {
        assertTrue(RouterSupportRegistry.detect("Huawei DN8245V-56").automatic)
        assertFalse(RouterSupportRegistry.detect("Huawei DN8245V").automatic)
        assertFalse(RouterSupportRegistry.detect("ZTE ZXHN H188A").automatic)
        assertFalse(RouterSupportRegistry.detect("TP-Link Archer VR600").automatic)
    }

    @Test
    fun `specific family wins before vendor fallback`() {
        assertEquals(
            "zte_fiber_ont",
            RouterSupportRegistry.detect("ZTE ZXHN F680").workflowId,
        )
        assertEquals(
            "huawei_mobile_cpe",
            RouterSupportRegistry.detect("Huawei B535-932").workflowId,
        )
    }

    @Test
    fun `unknown firmware never authorizes a write`() {
        val match = RouterSupportRegistry.detect("Unrecognized Egyptian ISP router")
        assertEquals("unknown", match.workflowId)
        assertFalse(match.automatic)
    }
}
