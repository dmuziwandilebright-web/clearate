import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() => _pkg = pkg);

    try {
      final checker = UpdateChecker();
      final update = await checker.fetch(AppScope.of(context).config);
      if (_isNewer(update.latestVersion, pkg.version)) {
        setState(() => _update = update);
      }
    } catch (_) {
      // Silent; More should still work offline.
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 24),
        // Brand section
        Center(
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida/AP1WRLuB9RxFNwFOizGtqZG3NxHNTLXFO-fugj0xuplfsTVbkKDVF2YtDbpCQm-r-VOXqaEm869YWO_uJSHn0Z7sqLpDLQ6YhtGXjl3R81aIRhe22aeQ6ucGTfjaPSglwx5PBhXeyYAHD_Yvfco52J3Ax36UYueL2FlrZlS7PSgBzHhrGW6WVqt2woAnNd1jVVYZAKOI-gjUix8eguaFNSnXe0dZENZoNJRuMxEcdAfLVyrhqU0Z6uGb_o2nA41D',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_balance_wallet,
                      size: 48,
                      color: theme.colorScheme.primaryContainerNavy,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Financial Truth',
                style: theme.textTheme.headlineLgMobile.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Providing clarity in a volatile world through objective currency data and transparent rates.',
                style: theme.textTheme.bodyMd.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_update != null) ...[
          _UpdateBanner(
            version: _update!.latestVersion,
            notes: _update!.releaseNotes,
            onTap: () => _open(_update!.apkUrl),
          ),
          const SizedBox(height: 16),
        ],
        // Menu groups
        // Preferences & Help Card
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              _buildMenuTile(
                icon: Icons.help_center,
                title: 'Support',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _SupportScreen()),
                ),
                theme: theme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Application Info Card
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              _buildMenuTile(
                icon: Icons.info,
                title: 'About',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _AboutScreen()),
                ),
                theme: theme,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuTile(
                icon: Icons.help_outline,
                title: 'FAQ',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _FaqScreen()),
                ),
                theme: theme,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuTile(
                icon: Icons.gavel,
                title: 'Legal',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _LegalScreen()),
                ),
                theme: theme,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildMenuTile(
                icon: Icons.storage,
                title: 'Rate Source',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _RateSourceScreen()),
                ),
                theme: theme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Version & Copy Metadata
        Center(
          child: Text(
            _pkg == null ? 'Version 1.0 (Build —)' : 'Version ${_pkg!.version} (Build ${_pkg!.buildNumber})',
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.secondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: theme.textTheme.bodyLg.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.version, required this.notes, required this.onTap});

  final String version;
  final String notes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.system_update, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New version available: v$version',
                    style: theme.textTheme.labelMd.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (notes.isNotEmpty)
                    Text(
                      notes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _SupportScreen extends StatelessWidget {
  const _SupportScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Future<void> email() async {
      final uri = Uri(
        scheme: 'mailto',
        path: 'support@clearate.app',
        queryParameters: {'subject': 'Clearate Support'},
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help?',
              style: theme.textTheme.headlineLgMobile.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Get in touch with our team for questions, feedback, or custom integrations.',
              style: theme.textTheme.bodyLg.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: email,
                icon: const Icon(Icons.email_outlined),
                label: const Text('Email Support'),
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

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Clearate',
            style: theme.textTheme.headlineLgMobile.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Clearate provides official exchange-rate information to help you verify fairness at the point of sale.\n\n'
            'It is designed for low data usage and works offline after saving the latest official rates.\n\n'
            'By empowering everyday users with direct, clean access to central banking reference rates, we eliminate guess-work, reduce inflation risk, and bring financial truth to local markets.',
            style: theme.textTheme.bodyLg.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '100% independent data utility. Clearate is not affiliated with any commercial brokerage or currency reseller.',
                    style: theme.textTheme.labelMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

class _LegalScreen extends StatelessWidget {
  const _LegalScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Disclaimer',
            style: theme.textTheme.headlineLgMobile.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Clearate is an information tool and is not a licensed financial advisor. '
            'Exchange rates shown are provided for reference and may not reflect rates offered by all retail institutions.\n\n'
            'By using this app, you agree that you are responsible for your own financial decisions.',
            style: theme.textTheme.bodyLg.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Text(
            'Terms of Service',
            style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Our data is pulled directly from public feeds. We make no guarantees about uptime, speed, or accuracy of currency exchanges conducted by secondary merchants.',
            style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Intro Hero Container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.help_center,
                  size: 56,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  'Financial Truth, Simplified.',
                  style: theme.textTheme.headlineMd.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Clearate is designed to give you clarity on Zimbabwe's exchange rates. Use this guide to master the tools available.",
            style: theme.textTheme.bodyLg.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          // Questions Accordion List
          _FaqItem(
            question: 'How do I use Price Check?',
            answer: 'Price Check helps you verify if a retailer\'s price matches official rates:\n\n'
                '1. Enter the USD Price of the item.\n'
                '2. Enter the ZAR or ZiG Price being charged by the shop.\n'
                '3. Clearate will automatically compare the two using current RBZ data.\n\n'
                '• FAIR: Within standard legal transaction margins.\n'
                '• OVERCHARGED: Rate exceeds official parameters.\n'
                '• UNDERVALUED: Rate is significantly below averages.',
          ),
          const SizedBox(height: 12),
          _FaqItem(
            question: 'How do I share rates without internet?',
            answer: 'Clearate features secure QR Sync code sharing:\n\n'
                '• Show QR: Generate a local scan-code on a device with updated rates.\n'
                '• Scan: Scan the QR code using another phone\'s camera to update its local database instantly. Works 100% offline.',
          ),
          const SizedBox(height: 12),
          _FaqItem(
            question: 'Where do the rates come from?',
            answer: 'All official exchange rates are retrieved directly from the Reserve Bank of Zimbabwe (RBZ) databases via the authorized ZimRate API, assuring absolute source integrity.',
          ),
          const SizedBox(height: 12),
          _FaqItem(
            question: 'The app is showing an old rate — is something wrong?',
            answer: 'No. Clearate caches (saves) the latest retrieved data to function offline. Pull down to refresh the home screen when you are back online to get the newest reference feeds.',
          ),
          const SizedBox(height: 12),
          _FaqItem(
            question: 'My phone says the APK is unsafe — should I install?',
            answer: 'This is a standard Android warning for apps downloaded outside the Google Play Store. Clearate is secure and open-source. As long as you download from our official web channels, it is completely safe.',
          ),
          const SizedBox(height: 12),
          _FaqItem(
            question: 'Does Clearate cost anything?',
            answer: 'Clearate is 100% free. Our primary goal is public utility and financial transparency for all citizens.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: theme.textTheme.headlineMd.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: theme.colorScheme.outline,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(), // Remove default borders on expansion
        collapsedShape: const Border(),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            answer,
            style: theme.textTheme.bodyMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateSourceScreen extends StatelessWidget {
  const _RateSourceScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Source')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified_user,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Authenticity',
                            style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'OFFICIAL FEED',
                            style: theme.textTheme.labelMd.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Clearate provides objective financial data to ensure transparency in every transaction. Our core commitment is to deliver "Financial Truth."',
                  style: theme.textTheme.bodyLg.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                  ),
                  child: Text(
                    'Rates sourced from RBZ via ZimRate API.',
                    style: theme.textTheme.bodyMd.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'DATA PROVIDERS',
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          // RBZ Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RBZ (Reserve Bank)',
                        style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The primary authority for official interbank exchange rates. These rates represent the weighted average of market trades.',
                        style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ZimRate API Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.api, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ZimRate API',
                        style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A specialized data aggregator that bridges official banking feeds with digital utility applications for real-time delivery.',
                        style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'API Connection: Active',
                              style: theme.textTheme.labelMd.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Refresh frequency Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFRESH FREQUENCY',
                      style: theme.textTheme.labelMd.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 10,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every 15 Minutes',
                      style: theme.textTheme.headlineMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.update,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Clearate is a public service utility. While we strive for 100% accuracy, users should verify critical financial data with their local banking institutions.',
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
