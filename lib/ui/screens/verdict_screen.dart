import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../domain/currency.dart';
import '../../domain/verdict.dart';
import '../../services/share_service.dart';
import '../../services/verdict_engine.dart';
import '../formatters.dart';
import '../theme.dart';

class VerdictScreen extends StatefulWidget {
  const VerdictScreen({super.key});

  @override
  State<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends State<VerdictScreen> {
  final _priceKnownController = TextEditingController();
  final _priceQuotedController = TextEditingController();
  final _shareKey = GlobalKey();
  final _shareService = ShareService();
  int _shareFailures = 0;

  Currency _from = Currency.usd;
  Currency _to = Currency.zwg;
  VerdictResult? _result;
  bool _isChecking = false;
  bool _knownError = false;
  bool _quotedError = false;

  @override
  void dispose() {
    _priceKnownController.dispose();
    _priceQuotedController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final controller = AppScope.of(context).ratesController;
    final snapshot = controller.state.snapshot;
    final theme = Theme.of(context);

    final known = double.tryParse(_priceKnownController.text.trim()) ?? 0;
    final quoted = double.tryParse(_priceQuotedController.text.trim()) ?? 0;

    setState(() {
      _knownError = known <= 0;
      _quotedError = quoted <= 0;
    });

    if (_knownError || _quotedError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.colorScheme.error,
          content: const Text('Please enter an amount.'),
        ),
      );
      return;
    }

    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select two different currencies to compare.')),
      );
      return;
    }

    if (snapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rates are not loaded yet. Open Rates while online first.')),
      );
      return;
    }

    final officialRate = snapshot.rate(_from, _to);
    if (officialRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pula rates are not loaded yet. Open Rates while online first.')),
      );
      return;
    }

    setState(() => _isChecking = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final engine = VerdictEngine(AppScope.of(context).config);
    final result = engine.evaluate(
      itemPrice: known,
      askedToPay: quoted,
      officialRate: officialRate,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _isChecking = false;
    });
  }

  Future<void> _shareImage() async {
    final boundary = _shareKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;

    final shareText = _buildShareText();
    try {
      await _shareService.sharePngFromBoundary(
        boundary: boundary,
        fileNameBase: 'clearate_verdict',
        text: shareText,
      );
      _shareFailures = 0;
    } catch (_) {
      _shareFailures += 1;
      if (!mounted) return;

      if (_shareFailures >= 2) {
        await _shareService.shareText(shareText);
        _shareFailures = 0;
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate share image. Try again.')),
      );
    }
  }

  String _buildShareText() {
    final result = _result;
    if (result == null) {
      return 'Clearate price check';
    }

    final verdictWord = switch (result.kind) {
      VerdictKind.fair => 'FAIR',
      VerdictKind.overcharged => 'OVERCHARGED',
      VerdictKind.undervalued => 'UNDERVALUED',
    };
    final amount = formatCurrencyAmount(_to, result.deltaAmount);
    final fair = formatCurrencyAmount(_to, result.expectedPay);
    final shop = formatCurrencyAmount(_to, result.askedToPay);
    return 'Clearate verdict: $verdictWord by $amount on a ${_from.uiLabel} to ${_to.uiLabel} check. '
        'Fair price $fair, shop price $shop.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Price Check',
          style: theme.textTheme.headlineLgMobile.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          "Instantly check if you're getting a fair exchange rate.",
          style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        _AmountCard(
          icon: Icons.account_balance_outlined,
          title: 'Price you know in',
          currency: _from,
          onCurrencyChanged: (value) => setState(() => _from = value),
          controller: _priceKnownController,
          error: _knownError,
          hint: '0.00',
        ),
        const SizedBox(height: 16),
        _AmountCard(
          icon: Icons.sell_outlined,
          title: 'Price they want in',
          currency: _to,
          onCurrencyChanged: (value) => setState(() => _to = value),
          controller: _priceQuotedController,
          error: _quotedError,
          hint: '0.00',
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isChecking ? null : _check,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isChecking
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      key: const ValueKey('idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Check Price',
                          style: theme.textTheme.headlineMd.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.gavel, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ),
        if (_from == _to) ...[
          const SizedBox(height: 8),
          Text(
            'Select two different currencies to compare.',
            style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.undervaluedAmber),
          ),
        ],
        const SizedBox(height: 18),
        RepaintBoundary(
          key: _shareKey,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: _result == null
                ? const _EmptyVerdictArea(key: ValueKey('empty'))
                : _VerdictCard(
                    key: ValueKey('${_result!.kind}-${_result!.askedToPay}-${_result!.itemPrice}'),
                    result: _result!,
                    from: _from,
                    to: _to,
                  ),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _shareImage,
              style: FilledButton.styleFrom(
                backgroundColor: _result!.kind == VerdictKind.fair
                    ? const Color(0xFF1B5E20)
                    : _result!.kind == VerdictKind.overcharged
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFFF57F17),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.share),
              label: const Text('Share Price Check'),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Price checks are based on the latest central bank mid-rates and a standard 8% retail margin.',
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.icon,
    required this.title,
    required this.currency,
    required this.onCurrencyChanged,
    required this.controller,
    required this.error,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final Currency currency;
  final ValueChanged<Currency> onCurrencyChanged;
  final TextEditingController controller;
  final bool error;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: error ? theme.colorScheme.error : theme.colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.labelMd.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              _CurrencyChip(
                currency: currency,
                onChanged: onCurrencyChanged,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            cursorColor: theme.colorScheme.primary,
            style: theme.textTheme.statLg.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 40,
              height: 1.0,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.statLg.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                fontSize: 40,
                height: 1.0,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (error) ...[
            const SizedBox(height: 8),
            Text(
              'Please enter an amount.',
              style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.currency,
    required this.onChanged,
  });

  final Currency currency;
  final ValueChanged<Currency> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<Currency>(
      onSelected: onChanged,
      itemBuilder: (context) => Currency.values
          .map(
            (value) => PopupMenuItem<Currency>(
              value: value,
              child: Text(value.uiLabel),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.uiLabel,
              style: theme.textTheme.labelMd.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _EmptyVerdictArea extends StatelessWidget {
  const _EmptyVerdictArea({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_outlined,
                size: 54,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter details to see if the price is fair.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLg.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    super.key,
    required this.result,
    required this.from,
    required this.to,
  });

  final VerdictResult result;
  final Currency from;
  final Currency to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (result.kind) {
      VerdictKind.fair => const Color(0xFFE0F5E6),
      VerdictKind.overcharged => const Color(0xFFB71C1C),
      VerdictKind.undervalued => const Color(0xFFF57F17),
    };
    final textColor = result.kind == VerdictKind.fair ? const Color(0xFF1B5E20) : Colors.white;
    final icon = switch (result.kind) {
      VerdictKind.fair => Icons.check_circle,
      VerdictKind.overcharged => Icons.close,
      VerdictKind.undervalued => Icons.warning_amber,
    };
    final verdictWord = switch (result.kind) {
      VerdictKind.fair => 'FAIR',
      VerdictKind.overcharged => 'OVERCHARGED',
      VerdictKind.undervalued => 'UNDERVALUED',
    };
    final description = switch (result.kind) {
      VerdictKind.fair => 'This price is honest. You are paying the correct official rate.',
      VerdictKind.overcharged => 'You are being asked for too much. You are being overcharged by ${formatCurrencyAmount(to, result.deltaAmount)}.',
      VerdictKind.undervalued => 'This price is very low. You are being undercharged by ${formatCurrencyAmount(to, result.deltaAmount)}.',
    };
    final deltaLine = switch (result.kind) {
      VerdictKind.fair => 'You are within ${formatCurrencyAmount(to, result.deltaAmount)} of the fair price.',
      VerdictKind.overcharged => 'Overcharged by ${formatCurrencyAmount(to, result.deltaAmount)}.',
      VerdictKind.undervalued => 'Undercharged by ${formatCurrencyAmount(to, result.deltaAmount)}.',
    };

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: result.kind == VerdictKind.fair
              ? const Color(0xFF8ED8A5)
              : result.kind == VerdictKind.overcharged
                  ? const Color(0xFFCC5B5B)
                  : const Color(0xFFD89A0F),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(result.kind == VerdictKind.fair ? 0.3 : 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: textColor),
          ),
          const SizedBox(height: 18),
          Text(
            verdictWord,
            style: theme.textTheme.displayLg.copyWith(
              color: textColor,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLg.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(result.kind == VerdictKind.fair ? 0.28 : 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              deltaLine,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMd.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ComparisonPanel(result: result, from: from, to: to, textColor: textColor),
        ],
      ),
    );
  }
}

class _ComparisonPanel extends StatelessWidget {
  const _ComparisonPanel({
    required this.result,
    required this.from,
    required this.to,
    required this.textColor,
  });

  final VerdictResult result;
  final Currency from;
  final Currency to;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final fair = result.expectedPay;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _ComparisonRow(
            label: 'Fair Price',
            value: formatCurrencyAmount(to, fair),
            valueColor: textColor,
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.35)),
          const SizedBox(height: 14),
          _ComparisonRow(
            label: 'Shop Price',
            value: formatCurrencyAmount(to, result.askedToPay),
            valueColor: textColor,
            labelTrailing: result.kind == VerdictKind.fair ? Icons.check_circle_outline : Icons.trending_up,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.labelTrailing,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData? labelTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: valueColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelMd.copyWith(
                      color: valueColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (labelTrailing != null) ...[
                    const SizedBox(width: 6),
                    Icon(labelTrailing, size: 16, color: valueColor),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.statLg.copyWith(
                  color: valueColor,
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
