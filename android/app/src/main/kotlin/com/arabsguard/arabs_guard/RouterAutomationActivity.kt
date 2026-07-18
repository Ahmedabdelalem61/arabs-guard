package com.arabsguard.arabs_guard

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.webkit.CookieManager
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebStorage
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import org.json.JSONObject
import org.json.JSONTokener

class RouterAutomationActivity : Activity() {
    private enum class Phase {
        DETECT,
        LOGIN_SENT,
        WAN_OPEN,
        WAN_SAVING,
        WAN_VERIFY,
        FIREWALL_OPEN,
        FIREWALL_SAVING,
        VERIFY,
        FINISHED,
    }

    private lateinit var webView: WebView
    private lateinit var status: TextView
    private lateinit var routerUri: Uri
    private var phase = Phase.DETECT
    private var username = ""
    private var password = ""
    private var model = "Unknown router"
    private var dnsVerified = false
    private var inspectionOnly = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        username = intent.getStringExtra(EXTRA_USERNAME).orEmpty()
        password = intent.getStringExtra(EXTRA_PASSWORD).orEmpty()
        inspectionOnly = intent.getBooleanExtra(EXTRA_INSPECTION_ONLY, false)
        val address = intent.getStringExtra(EXTRA_ADDRESS).orEmpty()
        intent.removeExtra(EXTRA_USERNAME)
        intent.removeExtra(EXTRA_PASSWORD)
        intent.removeExtra(EXTRA_INSPECTION_ONLY)

        val validated = validatePrivateRouterAddress(address)
        if (validated == null) {
            finishResult(
                ok = false,
                message = "Use a numeric private router address such as 192.168.1.1.",
                workflow = "invalid_address",
            )
            return
        }
        routerUri = validated
        setContentView(buildContent())
        configureWebView()
        status.text = if (inspectionOnly) {
            "Checking the router's public compatibility fingerprint…"
        } else {
            "Connecting securely to your router…"
        }
        clearRouterSession {
            if (phase != Phase.FINISHED) webView.loadUrl(routerUri.toString())
        }
    }

    private fun buildContent(): LinearLayout {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 64, 48, 48)
            setBackgroundColor(Color.rgb(246, 248, 251))
        }
        root.addView(TextView(this).apply {
            text = "Arabs Guard"
            textSize = 27f
            setTextColor(Color.rgb(6, 22, 47))
            gravity = Gravity.CENTER
        })
        root.addView(ProgressBar(this).apply { isIndeterminate = true }, linearParams(84, 84, 28))
        status = TextView(this).apply {
            textSize = 17f
            setTextColor(Color.rgb(43, 57, 78))
            gravity = Gravity.CENTER
        }
        root.addView(status, linearParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, 24))
        root.addView(TextView(this).apply {
            text = if (inspectionOnly) {
                "Read-only check: no credentials are sent and no setting is changed."
            } else {
                "Credentials stay on this phone and are cleared after setup."
            }
            textSize = 13f
            setTextColor(Color.rgb(105, 116, 135))
            gravity = Gravity.CENTER
        }, linearParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, 18))
        root.addView(Button(this).apply {
            text = "Cancel"
            setOnClickListener {
                finishResult(
                    false,
                    if (inspectionOnly) "Router compatibility check was cancelled."
                    else "Router setup was cancelled.",
                    "cancelled",
                )
            }
        }, linearParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT, 36))

        webView = WebView(this).apply {
            alpha = 0.01f
            clearCache(true)
        }
        root.addView(webView, LinearLayout.LayoutParams(1, 1))
        return root
    }

    private fun linearParams(width: Int, height: Int, topMargin: Int) =
        LinearLayout.LayoutParams(width, height).apply { this.topMargin = topMargin }

    private fun configureWebView() {
        WebView.setWebContentsDebuggingEnabled(false)
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = false
            allowContentAccess = false
            builtInZoomControls = false
            displayZoomControls = false
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(false)
        }
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean =
                !isSameRouter(request.url)

            override fun onReceivedSslError(view: WebView, handler: SslErrorHandler, error: android.net.http.SslError) {
                val errorUri = Uri.parse(error.url)
                if (isSameRouter(errorUri) && isPrivateIpv4(errorUri.host.orEmpty())) {
                    handler.proceed()
                } else {
                    handler.cancel()
                    finishResult(false, "The router certificate could not be accepted safely.", "certificate_error")
                }
            }

            override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
                if (request.isForMainFrame && phase != Phase.FINISHED) {
                    finishResult(false, "Could not reach the router. Connect to its Wi-Fi and try again.", "network_error")
                }
            }

            override fun onPageFinished(view: WebView, url: String) {
                super.onPageFinished(view, url)
                when (phase) {
                    Phase.DETECT -> detectRouter()
                    Phase.LOGIN_SENT -> checkLogin()
                    Phase.WAN_OPEN -> configureWanDns()
                    Phase.WAN_VERIFY -> verifyWanDns()
                    Phase.FIREWALL_OPEN -> configureFirewall()
                    Phase.VERIFY -> verifyFirewall()
                    else -> Unit
                }
            }
        }
    }

    private fun detectRouter() {
        evaluate(
            """
            (function() {
              return ((document.title || '') + ' ' + (document.body ? document.body.innerText : '')).slice(0, 20000);
            })();
            """.trimIndent(),
        ) { fingerprint ->
            val match = RouterSupportRegistry.detect(fingerprint)
            model = match.model
            if (inspectionOnly) {
                finishInspection(match)
                return@evaluate
            }
            when {
                match.automatic && match.workflowId == "huawei_dn8245v56" -> {
                    status.text = "Compatible Huawei model found. Verifying its page contract…"
                    submitHuaweiLogin()
                }
                else -> unsupported(match.model, match.workflowId)
            }
        }
    }

    private fun finishInspection(match: RouterMatch) {
        val recognized = match.hasDedicatedWorkflow
        val message = when {
            recognized && match.automatic ->
                "A compatible model was recognized from its public login page. " +
                    "The verified adapter will still re-check authenticated page structure before any change."
            recognized ->
                "A model-specific workflow was recognized from the public login page. " +
                    "Automatic changes remain disabled until this firmware is hardware-validated."
            else ->
                "The router responded, but its public login page did not reveal an exact supported model. " +
                    "No credentials were used and no settings were changed."
        }
        finishResult(
            ok = recognized,
            message = message,
            workflow = match.workflowId,
            detected = recognized,
            automaticEligible = recognized && match.automatic,
        )
    }

    private fun submitHuaweiLogin() {
        phase = Phase.LOGIN_SENT
        val usernameLiteral = JSONObject.quote(username)
        val passwordLiteral = JSONObject.quote(password)
        evaluate(
            """
            (function() {
              var u = document.getElementById('txt_Username');
              var p = document.getElementById('txt_Password');
              if (!u || !p) return 'already_signed_in';
              u.value = $usernameLiteral;
              p.value = $passwordLiteral;
              if (typeof LoginSubmit !== 'function') return 'unsupported_login';
              LoginSubmit('loginbutton');
              return 'submitted';
            })();
            """.trimIndent(),
        ) { result ->
            username = ""
            password = ""
            if (result == "already_signed_in") openWanPage()
            if (result == "unsupported_login") {
                finishResult(false, "This Huawei login firmware is not verified.", "huawei_unverified")
            }
        }
    }

    private fun checkLogin() {
        evaluate(
            """
            (function() {
              if (document.getElementById('txt_Username')) return 'login_form';
              return ((document.title || '') + ' ' + location.pathname).toLowerCase();
            })();
            """.trimIndent(),
        ) { result ->
            if (result == "login_form") {
                finishResult(false, "The router rejected the username or password.", "authentication_failed")
            } else {
                openWanPage()
            }
        }
    }

    private fun openWanPage() {
        if (phase == Phase.FINISHED) return
        phase = Phase.WAN_OPEN
        status.text = "Applying the family DNS policy…"
        webView.loadUrl(routerUrl("html/bbsp/wan/wan_tedata.asp"))
    }

    private fun configureWanDns() {
        evaluate(
            """
            (function() {
              if (typeof GetWanList !== 'function' || typeof setControl !== 'function' || typeof OnApply !== 'function') {
                return 'unsupported_page';
              }
              var list = GetWanList();
              var index = -1;
              for (var i = 0; i < list.length; i++) {
                var service = String(list[i].ServiceList || '').toUpperCase();
                var mode = String(list[i].Mode || '').toUpperCase();
                if (service.indexOf('INTERNET') >= 0 && mode.indexOf('IP_ROUTED') >= 0) { index = i; break; }
              }
              if (index < 0) return 'no_internet_wan';
              var wan = list[index];
              if (String(wan.IPv4PrimaryDNS) === '185.228.168.168' &&
                  String(wan.IPv4SecondaryDNS) === '185.228.169.168' &&
                  String(wan.IPv4DNSOverrideSwitch) === '1') return 'already';
              setControl(index);
              if (!document.getElementById('IPv4DNSOverrideSwitch')) return 'dns_locked';
              if (typeof setCheck === 'function') setCheck('IPv4DNSOverrideSwitch', 1);
              document.getElementById('IPv4DNSOverrideSwitch').checked = true;
              if (typeof OnChangeUI === 'function') OnChangeUI();
              setText('IPv4PrimaryDNSServer', '185.228.168.168');
              setText('IPv4SecondaryDNSServer', '185.228.169.168');
              OnApply();
              return 'submitted';
            })();
            """.trimIndent(),
        ) { result ->
            when (result) {
                "already" -> {
                    dnsVerified = true
                    openFirewallPage()
                }
                "submitted" -> {
                    phase = Phase.WAN_SAVING
                    webView.postDelayed({
                        if (phase != Phase.FINISHED) {
                            phase = Phase.WAN_VERIFY
                            status.text = "Verifying the DNS policy…"
                            webView.loadUrl(routerUrl("html/bbsp/wan/wan_tedata.asp"))
                        }
                    }, 5000)
                }
                "dns_locked" -> finishResult(false, "This account cannot change DNS on the router.", "dns_locked")
                "no_internet_wan" -> finishResult(false, "No editable Internet WAN connection was found.", "wan_not_found")
                else -> finishResult(false, "This Huawei WAN firmware is not verified.", "huawei_wan_unverified")
            }
        }
    }

    private fun verifyWanDns() {
        evaluate(
            """
            (function() {
              if (typeof GetWanList !== 'function') return 'not_verified';
              var list = GetWanList();
              var ok = list.some(function(w) {
                return String(w.ServiceList || '').toUpperCase().indexOf('INTERNET') >= 0 &&
                  String(w.Mode || '').toUpperCase().indexOf('IP_ROUTED') >= 0 &&
                  String(w.IPv4PrimaryDNS) === '185.228.168.168' &&
                  String(w.IPv4SecondaryDNS) === '185.228.169.168' &&
                  String(w.IPv4DNSOverrideSwitch) === '1';
              });
              return ok ? 'verified' : 'not_verified';
            })();
            """.trimIndent(),
        ) { result ->
            if (result == "verified") {
                dnsVerified = true
                openFirewallPage()
            } else {
                finishResult(false, "The router did not confirm the DNS policy.", "dns_verification_failed")
            }
        }
    }

    private fun openFirewallPage() {
        if (phase == Phase.FINISHED) return
        phase = Phase.FIREWALL_OPEN
        status.text = "Preventing common DNS bypass…"
        webView.loadUrl(routerUrl("html/bbsp/ipincoming/ipincoming.asp"))
    }

    private fun configureFirewall() {
        evaluate(
            """
            (function() {
              if (typeof FilterIn === 'undefined' || typeof setControl !== 'function') return 'unsupported_page';
              if (String(Mode) !== '2') return 'unsafe_policy';
              var rules = FilterIn.slice(0, Math.max(0, FilterIn.length - 1));
              var exists = rules.some(function(r) {
                return r && r.name === 'Block external DNS' && r.Protocol === 'TCP/UDP' &&
                  r.Direction === 'Upstream' && r.Action === 'Drop' &&
                  r.wanTcpPort === '53,853' && r.wanUdpPort === '53,853';
              });
              if (exists && String(enblIn) === '1') return 'already';
              if (exists) {
                document.getElementById('EnableIpFilter').checked = true;
                SubmitForm();
                return 'submitted';
              }
              setControl(-1);
              setText('RuleNameId', 'Block external DNS');
              setSelect('Protocol', 'TCP/UDP');
              setSelect('Direction', 'Upstream');
              setText('Priority', '10');
              setSelect('Action', 'Drop');
              setText('SourceIPStart', ''); setText('SourceIPEnd', '');
              setText('DestIPStart', ''); setText('DestIPEnd', '');
              setText('lanTcpPortId', ''); setText('lanUdpPortId', '');
              setText('wanTcpPortId', '53,853'); setText('wanUdpPortId', '53,853');
              document.getElementById('EnableIpFilter').checked = true;
              if (typeof protocalChange === 'function') protocalChange();
              SubmitEx();
              return 'submitted';
            })();
            """.trimIndent(),
        ) { result ->
            when (result) {
                "already" -> finishResult(
                    true,
                    "Family DNS and DNS-bypass rules are verified.",
                    "huawei_dn8245v56",
                )
                "submitted" -> {
                    phase = Phase.FIREWALL_SAVING
                    status.text = "Verifying protection…"
                    webView.postDelayed({
                        if (phase != Phase.FINISHED) {
                            phase = Phase.VERIFY
                            webView.loadUrl(routerUrl("html/bbsp/ipincoming/ipincoming.asp"))
                        }
                    }, 4500)
                }
                "unsafe_policy" -> finishFirewallFallback(
                    "The existing firewall policy is not the verified hybrid mode, so it was left unchanged.",
                    "firewall_policy_unverified",
                )
                else -> finishFirewallFallback(
                    "This Huawei firewall firmware is not verified, so it was left unchanged.",
                    "huawei_firewall_unverified",
                )
            }
        }
    }

    private fun verifyFirewall() {
        evaluate(
            """
            (function() {
              if (typeof FilterIn === 'undefined') return 'not_verified';
              var rules = FilterIn.slice(0, Math.max(0, FilterIn.length - 1));
              var ok = rules.some(function(r) {
                return r && r.name === 'Block external DNS' && r.Protocol === 'TCP/UDP' &&
                  r.Direction === 'Upstream' && r.Action === 'Drop' &&
                  r.wanTcpPort === '53,853' && r.wanUdpPort === '53,853';
              });
              return ok && String(enblIn) === '1' ? 'verified' : 'not_verified';
            })();
            """.trimIndent(),
        ) { result ->
            if (result == "verified") {
                finishResult(true, "Family DNS and DNS-bypass rules are verified.", "huawei_dn8245v56")
            } else {
                finishFirewallFallback(
                    "The router did not confirm the DNS-bypass firewall rule.",
                    "firewall_verification_failed",
                )
            }
        }
    }

    private fun finishFirewallFallback(detail: String, workflow: String) {
        if (dnsVerified) {
            finishResult(
                true,
                "Family DNS is verified. $detail Common DNS bypass hardening is incomplete.",
                "${workflow}_dns_only",
            )
        } else {
            finishResult(false, detail, workflow)
        }
    }

    private fun unsupported(detectedModel: String, workflow: String) {
        model = detectedModel
        finishResult(
            false,
            "A model-specific workflow exists, but this exact firmware is not yet verified for automatic changes.",
            workflow,
        )
    }

    private fun evaluate(script: String, callback: (String) -> Unit) {
        if (phase == Phase.FINISHED) return
        webView.evaluateJavascript(script) { raw ->
            val decoded = try {
                JSONTokener(raw).nextValue()?.toString().orEmpty()
            } catch (_: Exception) {
                raw.trim('"')
            }
            callback(decoded)
        }
    }

    private fun routerUrl(path: String): String {
        val current = Uri.parse(webView.url ?: routerUri.toString())
        return current.buildUpon().path("/$path").clearQuery().fragment(null).build().toString()
    }

    private fun isSameRouter(uri: Uri): Boolean =
        uri.host.equals(routerUri.host, ignoreCase = true) && isPrivateIpv4(uri.host.orEmpty())

    private fun validatePrivateRouterAddress(address: String): Uri? {
        val value = if (address.contains("://")) address else "https://$address"
        val uri = try {
            Uri.parse(value)
        } catch (_: Exception) {
            return null
        }
        if (uri.scheme !in listOf("http", "https")) return null
        if (uri.userInfo != null || !isPrivateIpv4(uri.host.orEmpty())) return null
        return uri.buildUpon().path(if (uri.path.isNullOrBlank()) "/" else uri.path).build()
    }

    private fun isPrivateIpv4(host: String): Boolean {
        val parts = host.split('.')
        if (parts.size != 4) return false
        val numbers = parts.map { it.toIntOrNull() ?: return false }
        if (numbers.any { it !in 0..255 }) return false
        return numbers[0] == 10 ||
            numbers[0] == 127 ||
            (numbers[0] == 169 && numbers[1] == 254) ||
            (numbers[0] == 172 && numbers[1] in 16..31) ||
            (numbers[0] == 192 && numbers[1] == 168)
    }

    private fun finishResult(
        ok: Boolean,
        message: String,
        workflow: String,
        detected: Boolean = false,
        automaticEligible: Boolean = false,
    ) {
        if (phase == Phase.FINISHED) return
        phase = Phase.FINISHED
        username = ""
        password = ""
        val result = Intent().apply {
            putExtra("ok", ok)
            putExtra("model", model)
            putExtra("message", message)
            putExtra("workflow", workflow)
            putExtra("detected", detected)
            putExtra("automaticEligible", automaticEligible)
        }
        setResult(if (ok) RESULT_OK else RESULT_CANCELED, result)
        finish()
    }

    override fun onDestroy() {
        username = ""
        password = ""
        if (::webView.isInitialized) {
            webView.stopLoading()
            webView.clearCache(true)
            webView.clearFormData()
            webView.clearHistory()
            webView.removeAllViews()
            webView.destroy()
        }
        WebStorage.getInstance().deleteAllData()
        CookieManager.getInstance().removeAllCookies(null)
        CookieManager.getInstance().flush()
        super.onDestroy()
    }

    private fun clearRouterSession(onCleared: () -> Unit) {
        WebStorage.getInstance().deleteAllData()
        val cookies = CookieManager.getInstance()
        cookies.removeAllCookies {
            cookies.flush()
            onCleared()
        }
    }

    companion object {
        const val EXTRA_ADDRESS = "router_address"
        const val EXTRA_USERNAME = "router_username"
        const val EXTRA_PASSWORD = "router_password"
        const val EXTRA_INSPECTION_ONLY = "router_inspection_only"
    }
}
