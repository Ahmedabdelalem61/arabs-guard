package com.arabsguard.arabs_guard

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RouterSupportRegistryTest {
    private data class RouterFixture(
        val workflowId: String,
        val automatic: Boolean,
        val fingerprint: String,
    )

    private fun egyptRouterFixtures(): List<RouterFixture> {
        val stream = checkNotNull(javaClass.classLoader?.getResourceAsStream("egypt_router_fixtures.txt")) {
            "Missing canonical Egyptian router fixture matrix."
        }
        return stream.bufferedReader().useLines { lines ->
            lines
                .filter { it.isNotBlank() && !it.startsWith('#') }
                .map { line ->
                    val columns = line.split('|', limit = 3)
                    check(columns.size == 3) { "Malformed router fixture: $line" }
                    RouterFixture(
                        workflowId = columns[0],
                        automatic = columns[1].toBooleanStrict(),
                        fingerprint = columns[2],
                    )
                }
                .toList()
        }
    }

    @Test
    fun `every canonical Egyptian fixture selects its dedicated workflow`() {
        egyptRouterFixtures().forEach { fixture ->
            val match = RouterSupportRegistry.detect(fixture.fingerprint)
            assertEquals(fixture.workflowId, match.workflowId)
            assertEquals(fixture.automatic, match.automatic)
        }
    }

    @Test
    fun `only exact model with a fail closed adapter enters automatic workflow`() {
        assertTrue(RouterSupportRegistry.detect("Huawei DN8245V-56").automatic)
        assertTrue(RouterSupportRegistry.detect("Huawei DN8245V‑56").automatic)
        assertFalse(RouterSupportRegistry.detect("Huawei DN8245V").automatic)
        assertFalse(RouterSupportRegistry.detect("Huawei DN8245V-560").automatic)
        assertFalse(RouterSupportRegistry.detect("Huawei XDN8245V-56").automatic)
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

    @Test
    fun `read only inspection reports only dedicated workflows as recognized`() {
        assertTrue(
            RouterSupportRegistry.detect("Huawei DN8245V-56").hasDedicatedWorkflow,
        )
        assertTrue(
            RouterSupportRegistry.detect("ZTE ZXHN H188A").hasDedicatedWorkflow,
        )
        assertFalse(
            RouterSupportRegistry.detect("Generic Huawei router").hasDedicatedWorkflow,
        )
        assertFalse(
            RouterSupportRegistry.detect("Unrecognized login page").hasDedicatedWorkflow,
        )
    }

    @Test
    fun `canonical matrix covers every dedicated Egyptian workflow`() {
        val expected = setOf(
            "huawei_dn8245v56",
            "zte_h188a",
            "huawei_fiber_ont",
            "zte_fiber_ont",
            "huawei_h153",
            "zte_k10",
            "zte_mifi",
            "zte_legacy",
            "huawei_mobile_cpe",
            "huawei_legacy",
            "tplink_dsl",
            "tplink_mobile",
            "dlink_dsl",
            "nokia_home",
            "tenda_dsl",
            "asus_dsl",
            "netgear_dsl",
            "technicolor_gateway",
        )

        assertEquals(expected, egyptRouterFixtures().map { it.workflowId }.toSet())
    }
}
