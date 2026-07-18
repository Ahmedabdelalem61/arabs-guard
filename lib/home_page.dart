import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'guard_platform.dart';
import 'region_roadmap.dart';
import 'router_catalog.dart';

const _demoMode = bool.fromEnvironment('DEMO_MODE');
const _navy = Color(0xFF06162F);
const _teal = Color(0xFF15B7A5);
const _gold = Color(0xFFF3B53F);

enum GuardMode { router, device, both }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _routerProtected = false;
  bool _deviceProtected = false;
  String _routerModel = 'Not checked';

  @override
  void initState() {
    super.initState();
    unawaited(_refreshVpn());
  }

  Future<void> _refreshVpn() async {
    if (kIsWeb) return;
    try {
      final active = await GuardPlatform.vpnStatus();
      if (mounted) setState(() => _deviceProtected = active);
    } on Object {
      // The native protection engine is Android-only.
    }
  }

  Future<void> _openSetup() async {
    final result = await Navigator.of(
      context,
    ).push<SetupResult>(MaterialPageRoute(builder: (_) => const SetupPage()));
    if (result == null || !mounted) return;
    setState(() {
      _routerProtected = result.routerProtected || _routerProtected;
      _deviceProtected = result.deviceProtected || _deviceProtected;
      if (result.routerModel.isNotEmpty) _routerModel = result.routerModel;
    });
  }

  Future<void> _openSupport() async {
    final uri = Uri.parse(
      'https://wa.me/2001011459031?text=${Uri.encodeComponent('Hello Arabs Guard support, I need help with my router.')}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final anyActive = _routerProtected || _deviceProtected;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            title: const Text('Arabs Guard'),
            actions: [
              IconButton(
                tooltip: 'WhatsApp support',
                onPressed: _openSupport,
                icon: const Icon(Icons.support_agent_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList.list(
              children: [
                _HeroCard(active: anyActive),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _StatusCard(
                        icon: Icons.router_rounded,
                        title: 'Home router',
                        subtitle: _routerProtected
                            ? _routerModel
                            : 'Not protected',
                        active: _routerProtected,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatusCard(
                        icon: Icons.phone_android_rounded,
                        title: 'This phone',
                        subtitle: _deviceProtected
                            ? 'DNS guard active'
                            : 'Not protected',
                        active: _deviceProtected,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _openSetup,
                  icon: const Icon(Icons.shield_rounded),
                  label: Text(
                    anyActive ? 'Protect another layer' : 'Set up protection',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('egypt-router-catalog'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RouterCatalogPage(),
                    ),
                  ),
                  icon: const Icon(Icons.hub_rounded),
                  label: const Text('Egypt router compatibility'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _RegionalExpansionCard(),
                const SizedBox(height: 22),
                const _PrivacyNote(),
                if (_demoMode) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'DEMO MODE · no router or VPN changes are made',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _teal, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_navy, Color(0xFF12345A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2206162F),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Image.asset('assets/branding/arabs_guard_icon.png'),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                active
                    ? 'Protection is active'
                    : 'A calmer internet starts here',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                active
                    ? 'Adult and unsafe domains are filtered at the layers you chose.'
                    : 'Block adult and unsafe domains on your router, phone, or both.',
                style: const TextStyle(color: Color(0xFFC7D5E7), height: 1.4),
              ),
              const SizedBox(height: 7),
              const Text(
                'حماية باختيارك وخصوصية افتراضية',
                textDirection: TextDirection.rtl,
                style: TextStyle(color: _gold, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 146),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE5EAF1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: active
              ? const Color(0xFFE3F8F4)
              : const Color(0xFFF0F2F6),
          foregroundColor: active ? _teal : const Color(0xFF7C8797),
          child: Icon(icon),
        ),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? _teal : const Color(0xFF768194),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF8F5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, color: _teal),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Router credentials are used only during setup and are never saved, logged, or uploaded. Browsing history is not collected.',
            style: TextStyle(height: 1.45, color: Color(0xFF29433F)),
          ),
        ),
      ],
    ),
  );
}

class _RegionalExpansionCard extends StatelessWidget {
  const _RegionalExpansionCard();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const Key('arabic-regions-coming-soon'),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RegionRoadmapPage())),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF102C50), Color(0xFF0B6D72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.public_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coming soon · قريباً',
                    style: TextStyle(color: _gold, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Arabic-world router coverage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'A transparent 22-country validation roadmap',
                    style: TextStyle(color: Color(0xFFC9E4E3), height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

class SetupResult {
  const SetupResult({
    required this.routerProtected,
    required this.deviceProtected,
    required this.routerModel,
  });

  final bool routerProtected;
  final bool deviceProtected;
  final String routerModel;
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController(text: '192.168.1.1');
  final _username = TextEditingController(text: _demoMode ? 'demo-admin' : '');
  final _password = TextEditingController(
    text: _demoMode ? 'demo-password' : '',
  );
  GuardMode _mode = GuardMode.both;
  bool _obscure = true;
  bool _routerConsent = false;
  bool _vpnConsent = false;
  bool _busy = false;
  bool _detectingRouter = false;
  String _progress = '';
  String _routerDetectionHint = '';

  bool get _usesRouter => _mode != GuardMode.device;
  bool get _usesDevice => _mode != GuardMode.router;

  @override
  void dispose() {
    _address.dispose();
    _username.dispose();
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _detectRouter() async {
    setState(() {
      _detectingRouter = true;
      _routerDetectionHint = '';
    });
    try {
      final gateway = _demoMode
          ? '192.168.1.1'
          : await GuardPlatform.detectRouterGateway();
      if (!mounted) return;
      if (gateway == null || gateway.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Connect to the router Wi-Fi and try detection again.',
            ),
          ),
        );
        return;
      }
      _address.text = gateway;
      setState(() {
        _routerDetectionHint =
            'Router found at $gateway. Its model and firmware will be fingerprinted before changes.';
      });
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Router detection was not available.')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingRouter = false);
    }
  }

  Future<void> _apply() async {
    if (!_formKey.currentState!.validate()) return;
    if ((_usesRouter && !_routerConsent) || (_usesDevice && !_vpnConsent)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the required disclosures.'),
        ),
      );
      return;
    }

    setState(() {
      _busy = true;
      _progress = 'Preparing protection…';
    });

    var routerOk = false;
    var deviceOk = false;
    var routerModel = '';
    var routerMessage = '';
    try {
      if (_usesRouter) {
        setState(() => _progress = 'Waiting for local-network consent…');
        final localNetworkAllowed = _demoMode
            ? true
            : await GuardPlatform.requestLocalNetworkConsent();
        if (!localNetworkAllowed) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Router protection needs Android Nearby devices permission to reach your router. No settings were changed.',
              ),
            ),
          );
          return;
        }
        setState(() => _progress = 'Detecting router and firmware…');
        final result = _demoMode
            ? await _demoRouterResult()
            : await GuardPlatform.configureRouter(
                address: _address.text.trim(),
                username: _username.text,
                password: _password.text,
              );
        _password.clear();
        routerOk = result.ok;
        routerModel = result.model;
        routerMessage = result.message;
        if (!result.ok) {
          if (!mounted) return;
          await _showRouterResult(result);
          if (_mode == GuardMode.router) return;
        }
      }

      if (_usesDevice) {
        setState(() => _progress = 'Waiting for Android VPN consent…');
        if (_demoMode) {
          await Future<void>.delayed(const Duration(milliseconds: 850));
          deviceOk = true;
        } else {
          final consent = await GuardPlatform.requestVpnConsent();
          if (consent) deviceOk = await GuardPlatform.startVpn();
        }
      }

      if (!mounted) return;
      final success = routerOk || deviceOk;
      if (success) {
        await _showSuccess(
          routerOk: routerOk,
          deviceOk: deviceOk,
          model: routerModel,
          routerMessage: routerMessage,
        );
        if (!mounted) return;
        Navigator.of(context).pop(
          SetupResult(
            routerProtected: routerOk,
            deviceProtected: deviceOk,
            routerModel: routerModel,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Protection was not enabled. No settings were changed.',
            ),
          ),
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Setup could not be completed.'),
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setup could not be completed safely.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = '';
        });
      }
    }
  }

  Future<RouterResult> _demoRouterResult() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return const RouterResult(
      ok: true,
      model: 'Huawei DN8245V-56 (simulated)',
      message: 'Family DNS and DNS-bypass rules verified.',
      workflow: 'huawei_dn8245v56',
    );
  }

  Future<void> _showRouterResult(RouterResult result) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.router_rounded, color: _gold, size: 34),
      title: Text(result.model),
      content: Text(
        '${result.message}\n\nNo unverified commands were sent to this router.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Continue'),
        ),
      ],
    ),
  );

  Future<void> _showSuccess({
    required bool routerOk,
    required bool deviceOk,
    required String model,
    required String routerMessage,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.verified_rounded, color: _teal, size: 42),
      title: const Text('Protection enabled'),
      content: Text(
        [
          if (routerOk) 'Router: ${model.isEmpty ? 'verified' : model}',
          if (routerOk && routerMessage.isNotEmpty) routerMessage,
          if (deviceOk) 'Phone: encrypted family DNS guard',
          if (deviceOk) '',
          if (deviceOk)
            'For stronger restart protection, open Android VPN settings and enable Always-on VPN. Leave “Block connections without VPN” off in this DNS-only release.',
        ].join('\n'),
      ),
      actions: [
        if (deviceOk && !_demoMode)
          TextButton(
            onPressed: GuardPlatform.openVpnSettings,
            child: const Text('VPN settings'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set up protection')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Text(
            'Choose protection layers',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Each layer is explained before Android or your router asks for consent.',
          ),
          const SizedBox(height: 20),
          for (final mode in GuardMode.values) ...[
            _ModeTile(
              mode: mode,
              selected: _mode == mode,
              onTap: _busy ? null : () => setState(() => _mode = mode),
            ),
            const SizedBox(height: 10),
          ],
          if (_usesRouter) ...[
            const SizedBox(height: 14),
            Text(
              'Router sign-in',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text('Connect this phone to the router Wi-Fi first.'),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('router-address-field'),
              controller: _address,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Router address',
                prefixIcon: Icon(Icons.language_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the router address.'
                  : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _busy || _detectingRouter ? null : _detectRouter,
                icon: _detectingRouter
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find_rounded),
                label: const Text('Auto-detect Wi-Fi router'),
              ),
            ),
            if (_routerDetectionHint.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                key: const Key('router-detection-hint'),
                _routerDetectionHint,
                style: const TextStyle(
                  color: _teal,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('router-username-field'),
              controller: _username,
              enabled: !_busy,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'Router username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter the router username.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('router-password-field'),
              controller: _password,
              enabled: !_busy,
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Router password',
                prefixIcon: const Icon(Icons.key_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter the router password.'
                  : null,
            ),
            const SizedBox(height: 10),
            Container(
              key: const Key('local-network-disclosure'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Local-network permission\n\nOn Android 17+, Android asks for Nearby devices access so Arabs Guard can connect directly to the numeric router address shown above. It does not scan nearby people, collect device identities, or use location.',
                style: TextStyle(height: 1.45, color: Color(0xFF5F4614)),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('router-consent'),
              contentPadding: EdgeInsets.zero,
              value: _routerConsent,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _routerConsent = value ?? false),
              title: const Text('I own or administer this router.'),
              subtitle: const Text(
                'Credentials stay in memory only and are cleared after setup.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          if (_usesDevice) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'VPN disclosure\n\nArabs Guard creates a local DNS-only VPN. Domain lookups are sent over encrypted DNS to CleanBrowsing Family Filter. The app does not inspect page contents, collect browsing history, or sell data. Android will show its own VPN consent dialog.',
                style: TextStyle(height: 1.45),
              ),
            ),
            CheckboxListTile(
              key: const Key('vpn-consent'),
              contentPadding: EdgeInsets.zero,
              value: _vpnConsent,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _vpnConsent = value ?? false),
              title: const Text(
                'I understand and agree to enable the DNS VPN.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          const SizedBox(height: 18),
          if (_busy) ...[
            const LinearProgressIndicator(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(height: 12),
            Text(_progress, textAlign: TextAlign.center),
          ] else
            FilledButton.icon(
              key: const Key('apply-protection'),
              onPressed: _apply,
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Apply protection'),
            ),
          const SizedBox(height: 12),
          const Text(
            'No consumer app can make protection literally irreversible: the router owner can reset a router and Android lets its owner uninstall apps. For commitment, let a trusted guardian keep router credentials and enable Android Always-on VPN.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF697487),
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final GuardMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (mode) {
      GuardMode.router => (
        Icons.router_rounded,
        'Router only',
        'Protect every device using home Wi-Fi',
      ),
      GuardMode.device => (
        Icons.phone_android_rounded,
        'This phone only',
        'Encrypted DNS guard wherever this phone goes',
      ),
      GuardMode.both => (
        Icons.health_and_safety_rounded,
        'Router + phone',
        'Recommended two-layer protection',
      ),
    };
    return Material(
      key: Key('guard-mode-${mode.name}'),
      color: selected ? const Color(0xFFE7F8F5) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? _teal : const Color(0xFFE3E8F0),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? _teal : const Color(0xFF667286),
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF697487)),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? _teal : const Color(0xFFBAC1CC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RouterCatalogPage extends StatelessWidget {
  const RouterCatalogPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Egypt router compatibility')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const Text(
          'Arabs Guard fingerprints the router first. Automatic adapters verify their required page structure at every phase; unknown or changed firmware receives no guessed commands.',
          style: TextStyle(height: 1.45),
        ),
        const SizedBox(height: 18),
        for (final profile in egyptRouterCatalog) ...[
          Card(
            key: Key('router-profile-${profile.workflowId}'),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE3E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    profile.automation == RouterAutomation.verified
                        ? Icons.verified_rounded
                        : profile.automation == RouterAutomation.guided
                        ? Icons.route_rounded
                        : Icons.radar_rounded,
                    color: profile.automation == RouterAutomation.verified
                        ? _teal
                        : _gold,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.carrier} · ${profile.vendor}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(profile.models),
                        const SizedBox(height: 8),
                        _RouterStatusBadge(automation: profile.automation),
                        const SizedBox(height: 8),
                        Text(
                          profile.workflow,
                          style: const TextStyle(
                            color: Color(0xFF697487),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        const Text(
          'Verified automatic = an exact model plus fail-closed runtime page checks and read-back verification. Guided = model-specific workflow awaiting hardware evidence. Firmware can vary even when the printed model is the same.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF697487),
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _RouterStatusBadge extends StatelessWidget {
  const _RouterStatusBadge({required this.automation});

  final RouterAutomation automation;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (automation) {
      RouterAutomation.verified => (
        'Verified automatic',
        const Color(0xFF087A6B),
        const Color(0xFFE4F7F2),
      ),
      RouterAutomation.guided => (
        'Guided workflow',
        const Color(0xFF8B5D00),
        const Color(0xFFFFF3D6),
      ),
      RouterAutomation.detectOnly => (
        'Detection only',
        const Color(0xFF596579),
        const Color(0xFFF0F3F7),
      ),
    };

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class RegionRoadmapPage extends StatelessWidget {
  const RegionRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Arabic-world roadmap')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مصر هي نقطة البداية',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: _teal,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Egypt is the current validation base. Other markets stay marked “coming soon” until provider models and exact firmware are researched and tested.',
                style: TextStyle(height: 1.45, color: Color(0xFF29433F)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final region in arabicRegionRoadmap) ...[
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFE3E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFF4DC),
                        foregroundColor: Color(0xFF9A6610),
                        child: Icon(Icons.schedule_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              region.arabicName,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              region.englishName,
                              style: const TextStyle(color: Color(0xFF697487)),
                            ),
                          ],
                        ),
                      ),
                      const _ComingSoonBadge(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final country in region.countries)
                        Chip(
                          label: Text(country),
                          side: BorderSide.none,
                          backgroundColor: const Color(0xFFF0F4F8),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    region.nextStep,
                    style: const TextStyle(
                      color: Color(0xFF697487),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        const Text(
          'Listed countries are roadmap scope, not verified compatibility. Automatic router changes remain disabled until exact firmware behavior is captured and regression-tested.',
          style: TextStyle(
            color: Color(0xFF697487),
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4DC),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Text(
      'SOON',
      style: TextStyle(
        color: Color(0xFF8B5B07),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: .7,
      ),
    ),
  );
}
