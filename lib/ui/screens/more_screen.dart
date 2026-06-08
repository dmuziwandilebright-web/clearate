import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_scope.dart';
import '../../services/update_checker.dart';
import '../theme.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  PackageInfo? _pkg;
  UpdateInfo? _update;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pkg = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _pkg = pkg);

    try {
      final checker = UpdateChecker();
      final update = await checker.fetch(AppScope.of(context).config);
      if (!mounted) return;
      if (_isNewer(update.latestVersion, pkg.version)) {
        setState(() => _update = update);
      }
    } catch (_) {
      // Silent by design.
    }
  }

  bool _isNewer(String latest, String current) {
    List<int> parts(String v) => v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final a = parts(latest);
    final b = parts(current);
    for (var i = 0; i < 3; i++) {
      final ai = i < a.length ? a[i] : 0;
      final bi = i < b.length ? b[i] : 0;
      if (ai != bi) return ai > bi;
    }
    return false;
  }

  Future<void> _open(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionLabel = _pkg == null
        ? 'Checking version...'
        : 'Version ${_pkg!.version} (Build ${_pkg!.buildNumber})';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const _LogoBadge(),
              const SizedBox(height: 14),
              Text(
                'Financial Truth',
                style: theme.textTheme.headlineLgMobile.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Showing reference rates first, then live rates as soon as the device connects.',
                style: theme.textTheme.bodyMd.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.offline_bolt_outlined,
                      title: 'Offline ready',
                      body: 'Keeps the last saved rates on the device.',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.qr_code_2_outlined,
                      title: 'QR sharing',
                      body: 'Share live rates with nearby phones.',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FeatureTile(
                      icon: Icons.gavel_outlined,
                      title: 'Price checks',
                      body: 'See if a quote is fair before paying.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_update != null) ...[
          _UpdateBanner(
            version: _update!.latestVersion,
            notes: _update!.releaseNotes,
            onTap: () => _open(_update!.apkUrl),
          ),
          const SizedBox(height: 16),
        ],
        _MenuGroup(
          items: [
            _MenuItemData(
              icon: Icons.help_center_outlined,
              title: 'Support',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _SupportScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MenuGroup(
          items: [
            _MenuItemData(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _AboutScreen()),
              ),
            ),
            _MenuItemData(
              icon: Icons.help_outline,
              title: 'FAQ',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _FaqScreen()),
              ),
            ),
            _MenuItemData(
              icon: Icons.gavel_outlined,
              title: 'Legal',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _LegalScreen()),
              ),
            ),
            _MenuItemData(
              icon: Icons.storage_outlined,
              title: 'Rate Source',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _RateSourceScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            versionLabel,
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '© 2026 Clearate Financial Technologies',
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return const _ClearateLogoMark();
  }
}

class _ClearateLogoMark extends StatelessWidget {
  const _ClearateLogoMark({
    this.size = 112,
    this.padding = 18,
  });

  final double size;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: CustomPaint(painter: _ClearateLogoPainter()),
      ),
    );
  }
}

class _ClearateLogoPainter extends CustomPainter {
  const _ClearateLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = size.shortestSide * 0.11
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = size.shortestSide * 0.11
      ..strokeCap = StrokeCap.round;
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeWidth = size.shortestSide * 0.095
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.41),
      size.shortestSide * 0.24,
      circlePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.60, size.height * 0.57),
      Offset(size.width * 0.82, size.height * 0.79),
      linePaint,
    );
    final check = Path()
      ..moveTo(size.width * 0.31, size.height * 0.35)
      ..lineTo(size.width * 0.40, size.height * 0.52)
      ..lineTo(size.width * 0.52, size.height * 0.41);
    canvas.drawPath(check, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _ClearateLogoPainter oldDelegate) => false;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurface, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.labelMd.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.labelMd.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  _MenuItemData({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.outlineVariant),
            _MenuTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _MenuItemData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: item.onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(item.icon, color: theme.colorScheme.secondary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.bodyLg.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({
    required this.version,
    required this.notes,
    required this.onTap,
  });

  final String version;
  final String notes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New version available: $version',
              style: theme.textTheme.labelMd.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              notes,
              style: theme.textTheme.bodyMd.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to download',
              style: theme.textTheme.labelMd.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectedToSource = AppScope.of(context).ratesController.state.snapshot?.serverTime != null;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Text('About', style: theme.textTheme.headlineMd.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Center(
            child: Column(
              children: [
                const _ClearateLogoMark(size: 104, padding: 18),
                const SizedBox(height: 18),
                Text(
                  'Clearate',
                  style: theme.textTheme.displayLg.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Financial Truth for Every Zimbabwean',
                  style: theme.textTheme.bodyLg.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Clearate was built in Plumtree, Zimbabwe by an 18-year-old developer who got tired of standing in a shop not knowing whether the exchange rate being quoted was honest. Not just for buyers - for anyone who touches more than one currency. The vendor pricing their tomatoes. The person changing rands at the bureau. The tuckshop owner working out what to charge. The family receiving money from abroad. If a rate is involved and you want to know if it is fair, Clearate tells you in three seconds.\n\nEvery feature exists because a real Zimbabwean needed it. The rates come directly from the Reserve Bank of Zimbabwe. The Price Check works offline. The QR sharing works without internet. Nothing in this app is decoration - it is all here because it solves something real.',
              style: theme.textTheme.bodyLg.copyWith(
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is version 1.0. It will keep getting better.',
                    style: theme.textTheme.labelMd.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _IdentityCard(
                  icon: Icons.person_pin,
                  iconBackground: Colors.black,
                  iconColor: Colors.white,
                  label: 'Founder',
                  value: 'Muziwandile B. Dube',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _IdentityCard(
                  icon: Icons.location_on,
                  iconBackground: const Color(0xFFD3E4FE),
                  iconColor: const Color(0xFF0B1C30),
                  label: 'Origin',
                  value: 'Plumtree, Zim',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () async {
                await launchUrl(
                  Uri.parse('https://wa.me/263771479216'),
                  mode: LaunchMode.externalApplication,
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
              icon: const Icon(Icons.share),
              label: const Text('Share Financial Clarity'),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Founded by Muziwandile Bright Dube. Plumtree, Zimbabwe · 2026. A Britek product.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMd.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportScreen extends StatelessWidget {
  const _SupportScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Text('Support', style: theme.textTheme.headlineMd.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFD3E4FE),
                  child: Icon(Icons.contact_support, color: const Color(0xFF0B1C30), size: 28),
                ),
                const SizedBox(height: 18),
                Text(
                  'Support',
                  style: theme.textTheme.headlineLgMobile.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Having a problem or want to give feedback? We want to hear from you.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Frequently Asked',
                  style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _FaqScreen())),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SupportPill(
            icon: Icons.help_outline,
            title: 'How are rates calculated?',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _FaqScreen())),
          ),
          const SizedBox(height: 10),
          _SupportPill(
            icon: Icons.update,
            title: 'How often is data updated?',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _RateSourceScreen())),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF10162A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'Contact Us',
                      style: theme.textTheme.headlineMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Message us on WhatsApp with your question, a screenshot if relevant, and the phone model you are using. We will get back to you as fast as we can.',
                  style: theme.textTheme.bodyMd.copyWith(color: Colors.white.withOpacity(0.72)),
                ),
                const SizedBox(height: 18),
                _WhatsAppRow(
                  number: '+263771479216',
                  uri: Uri.parse('https://wa.me/263771479216'),
                ),
                const SizedBox(height: 10),
                _WhatsAppRow(
                  number: '+263780464255',
                  uri: Uri.parse('https://wa.me/263780464255'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Note - these are personal numbers while Clearate is in early launch. Response times may vary. A dedicated support line is coming soon.',
              style: theme.textTheme.bodyMd.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'Before you message - check the FAQ above. Most questions are answered there and you will get a faster answer than waiting for a reply.',
              style: theme.textTheme.bodyMd.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report, color: theme.colorScheme.error),
                    const SizedBox(width: 10),
                    Text(
                      'Found a bug?',
                      style: theme.textTheme.headlineMd.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Tell us exactly what you did before the issue occurred. Screenshots are very helpful!',
                  style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await launchUrl(
                        Uri.parse('https://wa.me/263771479216?text=${Uri.encodeComponent('Clearate bug report')}'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: const Text('Report an Issue'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD3E4FE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: const Color(0xFF0B1C30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Our support hours are Monday to Friday, 8:00 AM to 5:00 PM (CAT).',
                    style: theme.textTheme.bodyMd.copyWith(color: const Color(0xFF0B1C30)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqScreen extends StatelessWidget {
  const _FaqScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Text('FAQ', style: theme.textTheme.headlineMd.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF10162A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Financial Truth, Simplified.',
                  style: theme.textTheme.bodyLg.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Clearate is designed to give you clarity on Zimbabwe\'s exchange rates. Use this guide to master the tools available.',
            style: theme.textTheme.bodyLg.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          _FaqAccordion(
            title: 'How do I use Price Check?',
            body:
                'Price Check is for anyone involved in a transaction where two currencies meet - buying, selling, exchanging, or receiving payment. It tells you whether the rate you are being given is fair based on today\'s official RBZ rate.\n\n'
                'Open the Price Check tab. You will see two fields.\n\n'
                'The first field says "Price you know in" followed by a currency dropdown. This is the amount you already know the value of. If something is priced at \$1, type 1 and select USD. If you are selling tomatoes worth R50, type 50 and select ZAR.\n\n'
                'The second field says "Price you are quoted in" followed by a currency dropdown. This is what the other person is asking you to pay or offering you. Type that number and select its currency.\n\n'
                'Tap the check button. Clearate gives you one of three verdicts instantly.\n\n'
                'FAIR in green means the rate being applied is within the acceptable range of today\'s official rate. The transaction is honest.\n\n'
                'OVERCHARGED in red means you are being asked to pay more than the fair rate allows. The exact amount you are being overcharged is shown - not a percentage, a real number in the currency you are paying.\n\n'
                'UNDERVALUED in amber means you are being offered less than the fair rate. This applies when you are selling or exchanging and the offer is below what the official rate justifies.\n\n'
                'Example for a buyer - a shop says \$1 bread costs R22. You type 1 in the first field, select USD, type 22 in the second field, select ZAR. Clearate tells you if R22 is a fair exchange for \$1 today.\n\n'
                'Example for a seller - you are selling goods worth \$10 and someone offers you R150. You type 10 in the first field, select USD, type 150 in the second field, select ZAR. Clearate tells you if R150 is a fair amount for \$10 worth of goods today.\n\n'
                'Example for a money changer - someone offers you 13 ZiG for \$1. You type 1 in the first field, select USD, type 13 in the second field, select ZiG. Clearate tells you if that rate is fair against the official RBZ rate.',
            positiveLabel: 'FAIR',
            positiveText: 'The transaction is honest.',
            dangerLabel: 'OVERCHARGED',
            dangerText: 'You are being asked to pay more than the fair rate allows.',
            infoLabel: 'UNDERVALUED',
            infoText: 'The offer is below what the official rate justifies.',
          ),
          const SizedBox(height: 10),
          _FaqItem(
            title: 'How do I share rates without internet?',
            body:
                'If you have today\'s rates and someone near you does not have internet, you can share your rates with them directly. No internet is needed on either phone.\n\n'
                'On the Rates screen tap Show QR. Your phone displays a QR code containing today\'s rates and the exact time they were fetched.\n\n'
                'The other person opens Clearate, taps Scan, and points their camera at your screen. Their app reads the rates from your QR code and updates instantly. They see the same rates you have along with a timestamp showing when the rates were originally fetched.\n\n'
                'If their rates are already newer than yours, Clearate tells them - "Your rates are more up to date. Show your QR code instead." This way the person with the most recent rates always shares, not the other way around.\n\n'
                'The QR code contains only rate data. No personal information. Nothing is sent to any server. It is purely device to device.',
          ),
          const SizedBox(height: 10),
          _FaqItem(
            title: 'Where do the rates come from?',
            body:
                'All rates are the official Reserve Bank of Zimbabwe interbank rates fetched through the ZimRate API by Statotec. Clearate reads and displays the official published rate - it does not set, adjust, or influence rates in any way. Source: zimrate.statotec.com',
          ),
          const SizedBox(height: 10),
          _FaqItem(
            title: 'The app is showing an old rate - is something wrong?',
            body:
                'No. Clearate saves the last fetched rate on your phone so it always has a number to show even without internet. If the timestamp shows yesterday or earlier it means the app has not been able to fetch a new rate yet - either because you have no data connection or the app has not been opened today while connected. Connect to WiFi or mobile data and open the app. The rate updates automatically. The timestamp always shows exactly when the rate was last fetched so you always know how current your data is.',
          ),
          const SizedBox(height: 10),
          _FaqItem(
            title: 'My phone says the APK is unsafe - should I install it?',
            body:
                'Yes it is safe. Android shows this warning for any app installed outside the Google Play Store - it is a standard system message that appears for all apps distributed this way, not a specific problem with Clearate. To install, tap Settings on the warning screen and enable Install from this source. Clearate will be available on the Play Store soon for users who prefer that route.',
          ),
          const SizedBox(height: 10),
          _FaqItem(
            title: 'Does Clearate work on any network?',
            body:
                'Yes. Clearate is not connected to any telecom network. It works the same on Econet, NetOne, Telecel, or any other SIM. It also works on WiFi with no SIM at all. The rates it fetches are the official RBZ rates which are the same for everyone.',
          ),
          const SizedBox(height: 10),
          _FaqItem(
            title: 'Does Clearate cost anything?',
            body:
                'The full app is free. Rates, Price Check, Converter, and QR sharing are all free with no limits and no hidden charges. A Pro tier with additional features will be introduced in a future update. Everything you have now will always remain free.',
          ),
          const SizedBox(height: 18),
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF1F3F5), Color(0xFFE6E8EA)],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'ZIMBABWE FINANCIAL TRUTH V1.0',
              style: theme.textTheme.labelMd.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalScreen extends StatelessWidget {
  const _LegalScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Text('Legal', style: theme.textTheme.headlineMd.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Text(
            'Transparency & Trust',
            style: theme.textTheme.displayLg.copyWith(fontSize: 40, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Understanding how Clearate protects you and the data that empowers your financial decisions.',
            style: theme.textTheme.bodyLg.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          _LegalCard(
            icon: Icons.gavel,
            title: 'Terms of Use',
            body:
                'Clearate is an information tool built to help Zimbabweans access official exchange rate data and make more informed decisions about currency transactions. It is not a licensed financial advisor, currency dealer, investment service, or banking product. Nothing displayed in this application constitutes financial advice.\n\n'
                'Exchange rate data is sourced from the Reserve Bank of Zimbabwe via the ZimRate API and is provided in good faith. Britek makes no guarantee of the accuracy, completeness, or timeliness of any rate data displayed. Users are responsible for verifying important financial decisions through official banking channels before acting on them.\n\n'
                'By using Clearate you agree that Britek and its founder bear no liability for any financial decisions made based on information displayed in this application. Use this app as one source of information, not the only one.',
            calloutTitle: 'Important',
            calloutBody: 'Rates are subject to rapid market volatility.',
          ),
          const SizedBox(height: 16),
          _LegalCard(
            icon: Icons.lock,
            title: 'Privacy Policy',
            body:
                'Clearate respects your privacy completely.\n\nAnonymous usage data is collected through Firebase Analytics. This includes app opens, screen views, and feature usage counts. No personal information, no names, no phone numbers, no transaction details, and no identifiable data is ever collected or stored on Britek servers.\n\nRate data fetched from the RBZ is cached locally on your device only. It never leaves your phone unless you choose to share it via the QR feature, which is purely device to device with no server involvement.\n\nClearate will never sell, share, or monetise any user data.',
          ),
          const SizedBox(height: 16),
          _LegalCard(
            icon: Icons.info,
            title: 'Disclaimer',
            body:
                'The fair price thresholds used in the Price Check feature are based on observed Zimbabwean retail market conditions and are intended as a general guide only. Individual transactions may have legitimate reasons for falling outside these ranges. Always use your own judgement.',
            calloutTitle: 'Use Your Judgement',
            calloutBody: 'Always use your own judgement.',
            calloutColor: const Color(0xFFFFE8E8),
            calloutTextColor: const Color(0xFF9F1E1E),
          ),
          const SizedBox(height: 18),
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEDEEF0), Color(0xFFD8DADC)],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.gavel_outlined, size: 72, color: Colors.black.withOpacity(0.1)),
                Text(
                  'LEGAL',
                  style: theme.textTheme.labelMd.copyWith(
                    color: Colors.black.withOpacity(0.3),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                const _ClearateLogoMark(size: 52, padding: 10),
                const SizedBox(height: 10),
                Text(
                  'Clearate',
                  style: theme.textTheme.bodyLg.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 Britek. Built in Zimbabwe.\nAll rights reserved.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Contact Support')),
                    TextButton(onPressed: () {}, child: const Text('Institutional Access')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateSourceScreen extends StatelessWidget {
  const _RateSourceScreen();

  Future<void> _openUrl(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectedToSource = AppScope.of(context).ratesController.state.snapshot?.serverTime != null;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Text('Rate Source', style: theme.textTheme.headlineMd.copyWith(color: Colors.white)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.sync),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3E4FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.verified_user, color: const Color(0xFF3F465C)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Authenticity',
                          style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'OFFICIAL FEED',
                          style: theme.textTheme.labelMd.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Clearate provides objective financial data to ensure transparency in every transaction. Our core commitment is to deliver "Financial Truth."',
                  style: theme.textTheme.bodyLg.copyWith(height: 1.45),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Rates sourced from RBZ via ZimRate API by Statotec.\nSource: zimrate.statotec.com',
                    style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'DATA PROVIDERS',
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          _ProviderCard(
            icon: Icons.account_balance,
            title: 'RBZ (Reserve Bank)',
            body:
                'The primary authority for official interbank exchange rates. These rates represent the weighted average of market trades.',
            action: 'Visit Website',
            onTapAction: () => _openUrl(context, Uri.parse('https://www.rbz.co.zw/')),
          ),
          const SizedBox(height: 12),
          _ProviderCard(
            icon: Icons.api,
            title: 'ZimRate API',
            body:
                'All rates are the official Reserve Bank of Zimbabwe interbank rates fetched through the ZimRate API by Statotec. Clearate reads and displays the official published rate - it does not set, adjust, or influence rates in any way.',
            footerChip: connectedToSource ? 'API Connection: Active' : null,
          ),
          const SizedBox(height: 18),
          Text(
            'Clearate is a public service utility. While we strive for 100% accuracy, users should verify critical financial data with their local banking institutions.',
            style: theme.textTheme.bodyMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: _ClearateLogoMark(size: 52, padding: 10)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Clearate',
              style: theme.textTheme.bodyLg.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 140,
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportPill extends StatelessWidget {
  const _SupportPill({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLg.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppRow extends StatelessWidget {
  const _WhatsAppRow({
    required this.number,
    required this.uri,
  });

  final String number;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline, color: Color(0xFF0B1C30)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                number,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0B1C30)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD3E4FE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF54647A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqAccordion extends StatelessWidget {
  const _FaqAccordion({
    required this.title,
    required this.body,
    required this.positiveLabel,
    required this.positiveText,
    required this.dangerLabel,
    required this.dangerText,
    required this.infoLabel,
    required this.infoText,
  });

  final String title;
  final String body;
  final String positiveLabel;
  final String positiveText;
  final String dangerLabel;
  final String dangerText;
  final String infoLabel;
  final String infoText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        title: Text(title, style: theme.textTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
        initiallyExpanded: true,
        iconColor: theme.colorScheme.onSurface,
        collapsedIconColor: theme.colorScheme.onSurfaceVariant,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(body, style: theme.textTheme.bodyMd.copyWith(height: 1.5)),
          const SizedBox(height: 14),
          _FaqVerdictChip(
            color: const Color(0xFFE8F5E9),
            textColor: const Color(0xFF1B5E20),
            label: positiveLabel,
            body: positiveText,
            icon: Icons.check_circle,
          ),
          const SizedBox(height: 10),
          _FaqVerdictChip(
            color: const Color(0xFFFFEBEE),
            textColor: const Color(0xFFB71C1C),
            label: dangerLabel,
            body: dangerText,
            icon: Icons.warning,
          ),
          const SizedBox(height: 10),
          _FaqVerdictChip(
            color: const Color(0xFFE8EEF8),
            textColor: const Color(0xFF54647A),
            label: infoLabel,
            body: infoText,
            icon: Icons.info,
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        title: Text(title, style: theme.textTheme.bodyLg.copyWith(fontWeight: FontWeight.w700)),
        iconColor: theme.colorScheme.onSurface,
        collapsedIconColor: theme.colorScheme.onSurfaceVariant,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(body, style: theme.textTheme.bodyMd.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _FaqVerdictChip extends StatelessWidget {
  const _FaqVerdictChip({
    required this.color,
    required this.textColor,
    required this.label,
    required this.body,
    required this.icon,
  });

  final Color color;
  final Color textColor;
  final String label;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label  -  $body',
              style: Theme.of(context).textTheme.bodyMd.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  const _LegalCard({
    required this.icon,
    required this.title,
    required this.body,
    this.calloutTitle,
    this.calloutBody,
    this.calloutColor,
    this.calloutTextColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? calloutTitle;
  final String? calloutBody;
  final Color? calloutColor;
  final Color? calloutTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = calloutTextColor ?? const Color(0xFF191C1E);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(body, style: theme.textTheme.bodyMd.copyWith(height: 1.5)),
          if (calloutTitle != null && calloutBody != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: calloutColor ?? const Color(0xFFF2F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E3E5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: textColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calloutTitle!,
                          style: theme.textTheme.labelMd.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          calloutBody!,
                          style: theme.textTheme.bodyMd.copyWith(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onTapAction,
    this.footerChip,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onTapAction;
  final String? footerChip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedAction = onTapAction ?? _noop;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMd.copyWith(height: 1.4)),
                if (action != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: action == null ? null : resolvedAction,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(action!, style: theme.textTheme.labelMd.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new, size: 16),
                      ],
                    ),
                  ),
                ],
                if (footerChip != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF1B5E20), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          footerChip!,
                          style: theme.textTheme.labelMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
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

void _noop() {}
