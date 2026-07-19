package com.arabsguard.arabs_guard

internal data class RouterMatch(
    val model: String,
    val workflowId: String,
    val automatic: Boolean = false,
) {
    val hasDedicatedWorkflow: Boolean
        get() = workflowId != "unknown" && !workflowId.endsWith("_unknown")
}

/**
 * Side-effect-free router fingerprinting shared by the WebView automation and
 * JVM regression tests. A match chooses a workflow; it never authorizes writes
 * unless [automatic] is true for an exact model with a validated, fail-closed
 * runtime page contract. The model match alone never proves firmware behavior.
 */
internal object RouterSupportRegistry {
    private val unicodeDash = Regex("[\\u2010-\\u2015\\u2212]")
    private val verifiedHuaweiDn8245v56 =
        Regex("(?<![a-z0-9])dn8245v[\\s_-]*56(?![a-z0-9])")

    fun detect(rawFingerprint: String): RouterMatch {
        val value = rawFingerprint
            .lowercase()
            .replace(unicodeDash, "-")
            .replace('\u00a0', ' ')
        return when {
            verifiedHuaweiDn8245v56.containsMatchIn(value) -> RouterMatch(
                "Huawei DN8245V-56",
                "huawei_dn8245v56",
                automatic = true,
            )
            value.contains("h188a") -> RouterMatch("ZTE ZXHN H188A family", "zte_h188a")
            hasAny(value, "hg8245w5", "hg8245", "eg8145", "eg8245") -> RouterMatch(
                "Huawei EchoLife fiber ONT family",
                "huawei_fiber_ont",
            )
            value.contains("h153") -> RouterMatch("Huawei H153 5G family", "huawei_h153")
            value.contains("zte") && value.contains("k10") -> RouterMatch(
                "ZTE K10 family",
                "zte_k10",
            )
            hasAny(value, "mf937", "mf971", "mf927") -> RouterMatch(
                "ZTE MiFi family",
                "zte_mifi",
            )
            hasAny(value, "f660", "f670", "f680", "f673") &&
                hasAny(value, "zte", "zxhn") -> RouterMatch(
                "ZTE ZXHN fiber ONT family",
                "zte_fiber_ont",
            )
            hasAny(value, "h168n", "h108n") -> RouterMatch(
                "ZTE ZXHN legacy DSL family",
                "zte_legacy",
            )
            hasAny(value, "b310", "b315", "b525", "b535", "b612", "b818", "h112", "h122", "h155") &&
                value.contains("huawei") -> RouterMatch(
                "Huawei mobile broadband CPE family",
                "huawei_mobile_cpe",
            )
            hasAny(value, "dg8045", "hg633", "hg630", "hg531", "hg532") -> RouterMatch(
                "Huawei legacy DSL gateway",
                "huawei_legacy",
            )
            hasModel(
                value,
                "archer vr300",
                "archer vr400",
                "archer vr600",
                "archer vr2100",
                "td-w9950",
                "td-w9960",
                "td-w9970",
                "td-w8961n",
                "archer vx1800v",
                "deco x20-dsl",
                "deco x50-dsl",
            ) -> RouterMatch("TP-Link DSL gateway family", "tplink_dsl")
            hasModel(
                value,
                "archer mr200",
                "archer mr400",
                "archer mr402",
                "archer mr500",
                "archer mr600",
                "tl-mr6400",
            ) ->
                RouterMatch("TP-Link mobile broadband family", "tplink_mobile")
            hasAny(value, "tp-link", "tplink") && hasModel(value, "m7005", "m7200") ->
                RouterMatch("TP-Link mobile Wi-Fi family", "tplink_mifi")
            hasModel(value, "archer nx200", "deco x50-5g") ->
                RouterMatch("TP-Link 5G CPE / mesh family", "tplink_5g")
            hasModel(
                value,
                "dsl-124",
                "dsl-224",
                "dsl-245ge",
                "dsl-2877",
                "dsl-2888",
                "dsl-2888a",
            ) -> RouterMatch(
                "D-Link DSL gateway family",
                "dlink_dsl",
            )
            hasAny(value, "d-link", "dlink") && hasModel(
                value,
                "dwr-910m",
                "dwr-921",
                "dwr-930m",
                "dwr-933",
                "dwr-933m",
                "dwr-953",
            ) -> RouterMatch("D-Link mobile broadband family", "dlink_mobile")
            value.contains("nokia") && hasAny(value, "beacon", "g-240", "g240") -> RouterMatch(
                "Nokia home gateway / mesh family",
                "nokia_home",
            )
            hasAny(value, "tenda v12", "tenda d301", "tenda d305") -> RouterMatch(
                "Tenda DSL gateway family",
                "tenda_dsl",
            )
            value.contains("asus") && value.contains("dsl-") -> RouterMatch(
                "ASUS DSL gateway family",
                "asus_dsl",
            )
            value.contains("netgear") && hasAny(value, "d6220", "d6400", "d7000") -> RouterMatch(
                "NETGEAR DSL gateway family",
                "netgear_dsl",
            )
            hasAny(value, "technicolor", "thomson") -> RouterMatch(
                "Technicolor / Thomson gateway family",
                "technicolor_gateway",
            )
            hasAny(value, "zxhn", "zte") -> RouterMatch("ZTE router", "zte_unknown")
            value.contains("huawei") -> RouterMatch("Huawei router", "huawei_unknown")
            hasAny(value, "tp-link", "tplink") -> RouterMatch("TP-Link router", "tplink_unknown")
            hasAny(value, "d-link", "dlink") -> RouterMatch("D-Link router", "dlink_unknown")
            value.contains("nokia") -> RouterMatch("Nokia router", "nokia_unknown")
            else -> RouterMatch("Unknown router or firmware", "unknown")
        }
    }

    private fun hasAny(value: String, vararg needles: String): Boolean =
        needles.any(value::contains)

    private fun hasModel(value: String, vararg models: String): Boolean =
        models.any { model ->
            Regex("(?<![a-z0-9])${Regex.escape(model)}(?![a-z0-9])").containsMatchIn(value)
        }
}
