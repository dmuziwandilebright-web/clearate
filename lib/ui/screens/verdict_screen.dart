import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_scope.dart';
import '../../domain/currency.dart';
import '../../domain/verdict.dart';
import '../../services/share_service.dart';
import '../../services/verdict_engine.dart';
import '../formatters.dart';
import '../theme.dart';
import '../widgets/section_card.dart';

class VerdictScreen extends StatefulWidget {
  const VerdictScreen({super.key});

  @override
  State<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends State<VerdictScreen> {
  final _itemName = TextEditingController();
  final _itemPrice = TextEditingController();
  final _askedPay = TextEditingController();

  Currency _from = Currency.usd;
  Currency _to = Currency.zwg;

  VerdictResult? _result;

  final _shareKey = GlobalKey();
  final _shareService = ShareService();

  @override
  void dispose() {
    _itemName.dispose();
    _itemPrice.dispose();
    _askedPay.dispose();
    super.dispose();
  }

  void _check() {
    final snapshot = AppScope.of(context).ratesController.state.snapshot;
    if (snapshot == null) {
      setState(() => _result = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved rates yet. Open Rates while online to fetch official rates.')),
      );
      return;
    }

    final itemPrice = double.tryParse(_itemPrice.text.trim()) ?? 0;
    final asked = double.tryParse(_askedPay.text.trim()) ?? 0;
    if (itemPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid item price.')));
      return;
    }

    final officialRate = snapshot.rate(_from, _to);
    final engine = VerdictEngine(AppScope.of(context).config);
    final res = engine.evaluate(itemPrice: itemPrice, askedToPay: asked, officialRate: officialRate);
    setState(() => _result = res);
  }

  Future<void> _shareImage() async {
    final boundary = _shareKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;

    final item = _itemName.text.trim();
    final name = item.isEmpty ? 'price_check' : item.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    await _shareService.sharePngFromBoundary(
      boundary: boundary,
      fileNameBase: 'clearate_$name',
      text: 'Check my price check on Clearate!',
    );
  }

  Future<void> _shareTextWhatsApp() async {
    if (_result == null) return;
    
    final item = _itemName.text.trim();
    final itemStr = item.isEmpty ? 'This purchase' : '*$item*';

    final text = switch (_result!.kind) {
      VerdictKind.fair => 
        'Clearate Price Verdict for $itemStr: *FAIR!*\n'
        'Official rate: 1 ${_from.uiLabel} = ${formatRate(_result!.officialRate)} ${_to.uiLabel}\n'
        'Shop rate: 1 ${_from.uiLabel} = ${formatRate(_result!.shopRate)} ${_to.uiLabel}\n'
        'This price is within the acceptable fair-market range.',
      VerdictKind.overcharged => 
        'Clearate Price Verdict for $itemStr: *OVERCHARGED!*\n'
        'Official rate: 1 ${_from.uiLabel} = ${formatRate(_result!.officialRate)} ${_to.uiLabel}\n'
        'Shop rate: 1 ${_from.uiLabel} = ${formatRate(_result!.shopRate)} ${_to.uiLabel}\n'
        'You are paying ${formatMoney(_result!.deltaAmount)} ${_to.uiLabel} more than fair price.',
      VerdictKind.undervalued => 
        'Clearate Price Verdict for $itemStr: *UNDERVALUED!*\n'
        'Official rate: 1 ${_from.uiLabel} = ${formatRate(_result!.officialRate)} ${_to.uiLabel}\n'
        'Shop rate: 1 ${_from.uiLabel} = ${formatRate(_result!.shopRate)} ${_to.uiLabel}\n'
        'This price is suspiciously below market average.',
    };

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Fair Price Verdict',
          style: theme.textTheme.headlineLgMobile.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          "Instantly check if you're getting a fair exchange rate.",
          style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        // Item Name input
        TextField(
          controller: _itemName,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'What are you buying? (Optional)',
            hintText: 'bread, airtime, fuel…',
          ),
        ),
        const SizedBox(height: 16),
        // Original Currency Input Card
        _InputCard(
          label: 'Item Price (Original Currency)',
          controller: _itemPrice,
          currency: _from,
          onCurrencyChanged: (c) => setState(() => _from = c),
        ),
        const SizedBox(height: 16),
        // Asked Currency Input Card
        _InputCard(
          label: 'What are you being asked to pay?',
          controller: _askedPay,
          currency: _to,
          onCurrencyChanged: (c) => setState(() => _to = c),
        ),
        const SizedBox(height: 20),
        // Check button
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _check,
            icon: const Icon(Icons.gavel),
            label: Text(
              'Check Verdict',
              style: theme.textTheme.headlineMd.copyWith(
                color: theme.colorScheme.onPrimary,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Results Area
        RepaintBoundary(
          key: _shareKey,
          child: _result == null
              ? const _EmptyVerdict()
              : _VerdictResultCard(
                  result: _result!,
                  from: _from,
                  to: _to,
                  itemName: _itemName.text.trim(),
                ),
        ),
        const SizedBox(height: 16),
        if (_result != null) ...[
          // Share Image Button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _shareImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Share Verdict Card'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Share WhatsApp Button
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _shareTextWhatsApp,
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('Share Price Check'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Verdicts are based on the latest central bank mid-rates and a standard 3% retail margin.",
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.label,
    required this.controller,
    required this.currency,
    required this.onCurrencyChanged,
  });

  final String label;
  final TextEditingController controller;
  final Currency currency;
  final ValueChanged<Currency> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.statLg.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Currency>(
                    value: currency,
                    items: Currency.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.uiLabel,
                                style: theme.textTheme.labelMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onCurrencyChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyVerdict extends StatelessWidget {
  const _EmptyVerdict();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter details to see if the price is fair.',
            style: theme.textTheme.bodyLg.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VerdictResultCard extends StatelessWidget {
  const _VerdictResultCard({
    required this.result,
    required this.from,
    required this.to,
    required this.itemName,
  });

  final VerdictResult result;
  final Currency from;
  final Currency to;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (badgeBg, badgeFg, badgeIcon, badgeText, headlineText, descText, cardBg) = switch (result.kind) {
      VerdictKind.fair => (
          theme.colorScheme.fairGreenBg,
          theme.colorScheme.fairGreen,
          Icons.check_circle,
          'FAIR',
          'Great Price!',
          'This price is within the acceptable fair-market range.',
          theme.colorScheme.fairGreenBg,
        ),
      VerdictKind.overcharged => (
          theme.colorScheme.overchargeRedBg,
          theme.colorScheme.overchargeRed,
          Icons.cancel,
          'OVERCHARGED',
          'Price is too high',
          "You're paying ~${(result.shopRate / result.officialRate - 1.0).clamp(0.0, 9.9) * 100.0 == 0 ? 'some' : (result.shopRate / result.officialRate - 1.0).clamp(0.0, 9.9).multiplyBy100().toStringAsFixed(0)}% more than the market fair rate.",
          theme.colorScheme.overchargeRedBg,
        ),
      VerdictKind.undervalued => (
          theme.colorScheme.undervaluedAmberBg,
          theme.colorScheme.undervaluedAmber,
          Icons.error_outline,
          'UNDERVALUED',
          'Suspiciously low',
          'This price is significantly below market average. Verify item authenticity.',
          theme.colorScheme.undervaluedAmberBg,
        ),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Header alert box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    badgeIcon,
                    size: 48,
                    color: badgeFg,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  badgeText,
                  style: theme.textTheme.headlineLgMobile.copyWith(
                    fontWeight: FontWeight.w800,
                    color: badgeFg,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  headlineText,
                  style: theme.textTheme.headlineMd.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descText,
                  style: theme.textTheme.bodyMd.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Price breakdown box
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRICE COMPARISON',
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                // Fair Price
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSecondaryContainer,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fair Price',
                          style: theme.textTheme.bodyMd.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${formatMoney(result.expectedPay)} ${to.uiLabel}',
                          style: theme.textTheme.headlineMd.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                // Shop Price (Asked Pay)
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: result.kind == VerdictKind.overcharged
                            ? theme.colorScheme.overchargeRed
                            : (result.kind == VerdictKind.undervalued
                                ? theme.colorScheme.undervaluedAmber
                                : theme.colorScheme.fairGreen),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shop Price',
                          style: theme.textTheme.bodyMd.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${formatMoney(result.shopRate * (result.expectedPay / result.officialRate))} ${to.uiLabel}',
                          style: theme.textTheme.headlineMd.copyWith(
                            fontWeight: FontWeight.bold,
                            color: result.kind == VerdictKind.overcharged
                                ? theme.colorScheme.overchargeRed
                                : (result.kind == VerdictKind.undervalued
                                    ? theme.colorScheme.undervaluedAmber
                                    : theme.colorScheme.fairGreen),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      result.kind == VerdictKind.overcharged
                          ? Icons.trending_up
                          : (result.kind == VerdictKind.undervalued ? Icons.trending_down : Icons.check_circle),
                      color: result.kind == VerdictKind.overcharged
                          ? theme.colorScheme.overchargeRed
                          : (result.kind == VerdictKind.undervalued
                              ? theme.colorScheme.undervaluedAmber
                              : theme.colorScheme.fairGreen),
                    ),
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

extension DoubleExt on double {
  double multiplyBy100() => this * 100.0;
}
