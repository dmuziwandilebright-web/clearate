import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/app_scope.dart';
import '../../domain/complaint_report.dart';
import '../../domain/currency.dart';
import '../../domain/rate_snapshot.dart';
import '../../domain/verdict.dart';
import '../../services/complaint_report_store.dart';
import '../../services/analytics_service.dart';
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
  ComplaintTransactionType _reportType = ComplaintTransactionType.goodsPurchase;
  VerdictResult? _result;
  bool _isChecking = false;
  bool _knownError = false;
  bool _quotedError = false;
  bool _showVerdict = false;

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.logScreenView('price_check_screen'));
  }

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
        const SnackBar(
            content: Text('Select two different currencies to compare.')),
      );
      return;
    }

    if (snapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Rates are not loaded yet. Open Rates while online first.')),
      );
      return;
    }

    final officialRate = snapshot.rate(_from, _to);
    if (officialRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Pula rates are not loaded yet. Open Rates while online first.')),
      );
      return;
    }

    setState(() => _isChecking = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final engine = const VerdictEngine();
    final result = engine.evaluate(
      itemPrice: known,
      askedToPay: quoted,
      officialRate: officialRate,
      thresholds: snapshot.thresholds,
    );

    if (!mounted) return;
    unawaited(
      AnalyticsService.logEvent(
        name: 'price_check_completed',
        parameters: {
          'verdict': switch (result.kind) {
            VerdictKind.fair => 'fair',
            VerdictKind.overcharged => 'overcharged',
            VerdictKind.undervalued => 'undervalued',
          },
          'from_currency': _from.uiLabel,
          'to_currency': _to.uiLabel,
        },
      ),
    );
    setState(() {
      _result = result;
      _showVerdict = true;
      _isChecking = false;
    });
  }

  void _clearVerdict() {
    setState(() {
      _result = null;
      _showVerdict = false;
      _shareFailures = 0;
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
        const SnackBar(
            content: Text('Could not generate share image. Try again.')),
      );
    }
  }

  Future<void> _openComplaintSheet() async {
    final result = _result;
    if (result == null) return;
    final snapshot = AppScope.of(context).ratesController.state.snapshot;

    final boundary = _shareKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;

    final cardFile = await _shareService.capturePngFromBoundary(
      boundary: boundary,
      fileNameBase: 'clearate_complaint_card',
    );

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ComplaintSheet(
          result: result,
          snapshot: snapshot,
          from: _from,
          to: _to,
          transactionType: _reportType,
          verdictCardPath: cardFile.path,
          priceKnown: double.tryParse(_priceKnownController.text.trim()) ?? 0,
          priceQuoted: double.tryParse(_priceQuotedController.text.trim()) ?? 0,
        );
      },
    );
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
    final fairLow = formatCurrencyAmount(_to, result.fairLowerAmount);
    final fairHigh = formatCurrencyAmount(_to, result.fairUpperAmount);
    return 'Clearate verdict: $verdictWord by $amount on a ${_from.uiLabel} to ${_to.uiLabel} check. '
        'Fair price $fair, shop price $shop. '
        '${result.retailMarginSummary}. Fair range $fairLow to $fairHigh.';
  }

  String _buildReportText() {
    final result = _result;
    if (result == null) {
      return 'Clearate price check report';
    }

    final verdictWord = switch (result.kind) {
      VerdictKind.fair => 'fair',
      VerdictKind.overcharged => 'overcharged',
      VerdictKind.undervalued => 'undervalued',
    };
    final fair = formatCurrencyAmount(_to, result.expectedPay);
    final shop = formatCurrencyAmount(_to, result.askedToPay);
    final margin = result.retailMarginSummary;
    final fairRange =
        '${formatCurrencyAmount(_to, result.fairLowerAmount)} to ${formatCurrencyAmount(_to, result.fairUpperAmount)}';
    return 'Clearate Price Check report\n'
        'Verdict: $verdictWord\n'
        'From: ${_from.uiLabel}\n'
        'To: ${_to.uiLabel}\n'
        'Fair price: $fair\n'
        'Shop price: $shop\n'
        '$margin\n'
        'Fair range: $fairRange';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Price Check',
          style: theme.textTheme.headlineLgMobile
              .copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What were you doing?',
                style: theme.textTheme.labelMd.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonHideUnderline(
                child: DropdownButton<ComplaintTransactionType>(
                  value: _reportType,
                  isExpanded: true,
                  alignment: Alignment.center,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  style: theme.textTheme.bodyLg.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                  selectedItemBuilder: (context) {
                    return ComplaintTransactionType.values
                        .map(
                          (value) => Center(
                            child: Text(
                              value.uiLabel,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLg.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList();
                  },
                  items: ComplaintTransactionType.values
                      .map(
                        (value) => DropdownMenuItem<ComplaintTransactionType>(
                          value: value,
                          child: Center(
                            child: Text(
                              value.uiLabel,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLg.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _reportType = value);
                  },
                ),
              ),
            ],
          ),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
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
            style: theme.textTheme.bodyMd
                .copyWith(color: theme.colorScheme.undervaluedAmber),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 14),
          Text(
            'ANALYSIS RESULT',
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Currency Evaluation',
            style: theme.textTheme.headlineLg.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 18),
        RepaintBoundary(
          key: _shareKey,
          child: !_showVerdict || _result == null
              ? const _EmptyVerdictArea(key: ValueKey('empty'))
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.96, end: 1.0),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    final opacity = ((scale - 0.96) / 0.04).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: _VerdictCard(
                    result: _result!,
                    from: _from,
                    to: _to,
                    onShare: _shareImage,
                    onReport: _openComplaintSheet,
                    onDismiss: _clearVerdict,
                  ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: error
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
              width: error ? 1.2 : 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(icon,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    Text(
                      title,
                      style: theme.textTheme.labelMd.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _CurrencyChip(
                      currency: currency,
                      onChanged: onCurrencyChanged,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(icon,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMd.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CurrencyChip(
                      currency: currency,
                      onChanged: onCurrencyChanged,
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                cursorColor: theme.colorScheme.primary,
                style: theme.textTheme.statLg.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: compact ? 34 : 40,
                  height: 1.0,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: theme.textTheme.statLg.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    fontSize: compact ? 34 : 40,
                    height: 1.0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (error) ...[
                const SizedBox(height: 8),
                Text(
                  'Please enter an amount.',
                  style: theme.textTheme.bodyMd
                      .copyWith(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        );
      },
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
            Icon(Icons.keyboard_arrow_down,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
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
    required this.result,
    required this.from,
    required this.to,
    required this.onShare,
    required this.onReport,
    required this.onDismiss,
  });

  final VerdictResult result;
  final Currency from;
  final Currency to;
  final Future<void> Function() onShare;
  final Future<void> Function() onReport;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = switch (result.kind) {
      VerdictKind.fair => const Color(0xFF128A43),
      VerdictKind.overcharged => const Color(0xFF9C1F1F),
      VerdictKind.undervalued => const Color(0xFFD89A0F),
    };
    final headerColor = switch (result.kind) {
      VerdictKind.fair => const Color(0xFFD7F6DD),
      VerdictKind.overcharged => const Color(0xFFB71C1C),
      VerdictKind.undervalued => const Color(0xFFFFB400),
    };
    final textColor = switch (result.kind) {
      VerdictKind.fair => const Color(0xFF147A39),
      VerdictKind.overcharged => Colors.white,
      VerdictKind.undervalued => Colors.black,
    };
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
      VerdictKind.fair =>
        'This price is honest. You are paying the correct official rate.',
      VerdictKind.overcharged =>
        'You are being asked for too much. You are being overcharged by ${formatCurrencyAmount(to, result.deltaAmount)}.',
      VerdictKind.undervalued =>
        'This price is very low. You are being undercharged by ${formatCurrencyAmount(to, result.deltaAmount)}.',
    };
    final deltaLine = switch (result.kind) {
      VerdictKind.fair =>
        'You are within ${formatCurrencyAmount(to, result.deltaAmount)} of the fair price.',
      VerdictKind.overcharged =>
        'Overcharged by ${formatCurrencyAmount(to, result.deltaAmount)}.',
      VerdictKind.undervalued =>
        'Undercharged by ${formatCurrencyAmount(to, result.deltaAmount)}.',
    };
    final glowShadow = switch (result.kind) {
      VerdictKind.fair => const [
          BoxShadow(
            color: Color(0x5534C759),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x2234C759),
            blurRadius: 44,
            offset: Offset(0, 0),
            spreadRadius: 4,
          ),
        ],
      VerdictKind.overcharged => const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      VerdictKind.undervalued => const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor),
        boxShadow: glowShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
              boxShadow: result.kind == VerdictKind.fair
                  ? const [
                      BoxShadow(
                        color: Color(0x2234C759),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: result.kind == VerdictKind.overcharged
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.42),
                          shape: BoxShape.circle,
                          boxShadow: result.kind == VerdictKind.fair
                              ? const [
                                  BoxShadow(
                                    color: Color(0x4434C759),
                                    blurRadius: 18,
                                    offset: Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: Color(0x2234C759),
                                    blurRadius: 28,
                                    offset: Offset(0, 0),
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            result.kind == VerdictKind.fair
                                ? Icons.check
                                : icon,
                            size: 34,
                            color: result.kind == VerdictKind.fair
                                ? const Color(0xFF128A43)
                                : textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        verdictWord,
                        style: theme.textTheme.displayLg.copyWith(
                          color: textColor,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.kind == VerdictKind.fair
                            ? 'Fair price'
                            : result.kind == VerdictKind.overcharged
                                ? 'Overcharge detected'
                                : 'Undervalued offer',
                        style: theme.textTheme.labelMd.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                    color: textColor,
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: switch (result.kind) {
              VerdictKind.fair => const Color(0xFFF4FDF6),
              VerdictKind.overcharged => const Color(0xFFFDF6F6),
              VerdictKind.undervalued => const Color(0xFFFFF4D6),
            },
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLg.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (result.isVolatile) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Rates are moving today - the fair range is wider than usual.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMd.copyWith(
                      color: const Color(0xFF7A4E00),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: result.kind == VerdictKind.fair
                        ? const Color(0xFFBDECCB)
                        : result.kind == VerdictKind.overcharged
                            ? const Color(0xFFFFE7E4)
                            : const Color(0xFFFFC300),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    deltaLine,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMd.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  result.retailMarginSummary,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _ComparisonPanel(
                  result: result,
                  from: from,
                  to: to,
                  textColor: Colors.black,
                ),
                const SizedBox(height: 10),
                Text(
                  result.thresholdSource == 'dynamic_spread'
                      ? 'Fair range based on today\'s market spread.'
                      : 'Fair range based on reference rate.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fair range: ${formatCurrencyAmount(to, result.fairLowerAmount)} to ${formatCurrencyAmount(to, result.fairUpperAmount)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onShare,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Price Check'),
                  ),
                ),
                if (result.kind != VerdictKind.fair) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onReport,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Send Report'),
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

class _ComplaintSheet extends StatefulWidget {
  const _ComplaintSheet({
    required this.result,
    required this.snapshot,
    required this.from,
    required this.to,
    required this.transactionType,
    required this.verdictCardPath,
    required this.priceKnown,
    required this.priceQuoted,
  });

  final VerdictResult result;
  final RateSnapshot? snapshot;
  final Currency from;
  final Currency to;
  final ComplaintTransactionType transactionType;
  final String verdictCardPath;
  final double priceKnown;
  final double priceQuoted;

  @override
  State<_ComplaintSheet> createState() => _ComplaintSheetState();
}

enum _ComplaintStage { form, confirmation, submitting }

class _ComplaintSheetState extends State<_ComplaintSheet> {
  final _formKey = GlobalKey<FormState>();
  final _businessController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _itemController = TextEditingController();
  _ComplaintStage _stage = _ComplaintStage.form;
  String? _town;
  String? _exchangeLocationType;
  bool _busy = false;
  String? _referenceNumber;

  @override
  void dispose() {
    _businessController.dispose();
    _descriptionController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final theme = Theme.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_town == null || _town!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.colorScheme.error,
          content: const Text('Please choose a town.'),
        ),
      );
      return;
    }
    if (widget.transactionType == ComplaintTransactionType.currencyExchange &&
        (_exchangeLocationType == null || _exchangeLocationType!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.colorScheme.error,
          content: const Text('Please choose where the exchange happened.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    final reference =
        'CPC-${DateTime.now().year}-${10000 + DateTime.now().millisecondsSinceEpoch.remainder(90000)}';
    final snapshot = widget.snapshot;
    final verdictText = switch (widget.result.kind) {
      VerdictKind.fair => 'fair',
      VerdictKind.overcharged => 'overcharged',
      VerdictKind.undervalued => 'undervalued',
    };
    final submittedAt = DateTime.now();
    final packageInfo = await PackageInfo.fromPlatform();
    final report = ComplaintReport(
      referenceNumber: reference,
      verdict: verdictText,
      transactionType: widget.transactionType,
      fromCurrency: widget.from.uiLabel,
      toCurrency: widget.to.uiLabel,
      priceKnown: widget.priceKnown,
      priceQuoted: widget.priceQuoted,
      fairPrice: widget.result.expectedPay,
      differenceAmount: widget.result.deltaAmount,
      differencePct: widget.result.expectedPay <= 0
          ? 0
          : (widget.result.deltaAmount / widget.result.expectedPay) * 100,
      thresholdUpperPct: widget.result.upperThresholdPct,
      thresholdLowerPct: widget.result.lowerThresholdPct,
      thresholdSource: widget.result.thresholdSource,
      marketVolatile: widget.result.isVolatile,
      rbzRate: widget.result.officialRate,
      rateDate: snapshot?.meta?.rateDate ??
          (snapshot?.serverTime != null
              ? snapshot!.serverTime!.toIso8601String()
              : ''),
      serverTime: snapshot?.serverTime?.toIso8601String() ??
          snapshot?.meta?.serverTime?.toIso8601String() ??
          '',
      appVersion: packageInfo.version,
      status: 'submitted',
      submittedAt: submittedAt,
      verdictCardUrl: widget.verdictCardPath,
      town: _town!,
      businessName: _businessController.text.trim().isEmpty
          ? null
          : _businessController.text.trim(),
      itemName: widget.transactionType == ComplaintTransactionType.goodsPurchase
          ? (_itemController.text.trim().isEmpty
              ? null
              : _itemController.text.trim())
          : null,
      exchangeLocationType:
          widget.transactionType == ComplaintTransactionType.currencyExchange
              ? _exchangeLocationType
              : null,
      description:
          widget.transactionType == ComplaintTransactionType.goodsPurchase
              ? (_descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim())
              : null,
    );

    try {
      await ComplaintReportStore.create().then((store) => store.save(report));
      await AnalyticsService.logEvent(
        name: 'complaint_submitted',
        parameters: {
          'verdict': verdictText,
          'town': _town!,
          'type': widget.transactionType.apiValue,
        },
      );
      if (!mounted) return;
      setState(() {
        _referenceNumber = reference;
        _stage = _ComplaintStage.confirmation;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the report. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: _stage == _ComplaintStage.confirmation
          ? _ComplaintConfirmationView(
              key: const ValueKey('confirmation'),
              referenceNumber: _referenceNumber ?? 'CPC-0000-00000',
              onCopy: () async {
                await Clipboard.setData(
                  ClipboardData(text: _referenceNumber ?? ''),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reference copied.')),
                );
              },
              onDone: () => Navigator.of(context).pop(),
            )
          : DraggableScrollableSheet(
              key: const ValueKey('form'),
              expand: false,
              initialChildSize: 0.92,
              minChildSize: 0.72,
              maxChildSize: 0.96,
              builder: (context, scrollController) {
                final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          _SheetHandle(color: theme.colorScheme.outlineVariant),
                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                controller: scrollController,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.fromLTRB(
                                  18,
                                  0,
                                  18,
                                  18 + bottomInset,
                                ),
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Send report',
                                          style: theme.textTheme.headlineLg
                                              .copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _busy
                                            ? null
                                            : () => Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  if (widget.transactionType ==
                                      ComplaintTransactionType.goodsPurchase)
                                    Text(
                                      'Report a possible pricing issue when buying something.',
                                      style: theme.textTheme.bodyMd.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Report a possible pricing issue when exchanging money.',
                                      style: theme.textTheme.bodyMd.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  _SectionHeader(
                                    title: 'Town',
                                    subtitle: 'Required',
                                  ),
                                  const SizedBox(height: 8),
                                  _SearchSelectField(
                                    label: 'Choose town',
                                    value: _town,
                                    options: _zimTowns,
                                    searchHint: 'Search town',
                                    onSelected: (value) =>
                                        setState(() => _town = value),
                                  ),
                                  const SizedBox(height: 14),
                                  if (widget.transactionType ==
                                      ComplaintTransactionType
                                          .goodsPurchase) ...[
                                    _SectionHeader(
                                      title: 'Business name',
                                      subtitle: 'Required for buying goods',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _businessController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: _fieldDecoration(
                                        theme,
                                        hintText: 'e.g. OK Supermarket',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Enter the business name.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _SectionHeader(
                                      title: 'Item name',
                                      subtitle: 'Optional',
                                    ),
                                    const SizedBox(height: 8),
                                    _SearchSelectField(
                                      label: 'Choose good',
                                      value: _itemController.text.isEmpty
                                          ? null
                                          : _itemController.text,
                                      options: _commonGoods,
                                      searchHint: 'Search goods',
                                      onSelected: (value) => setState(
                                          () => _itemController.text = value),
                                    ),
                                    const SizedBox(height: 14),
                                    _SectionHeader(
                                      title: 'Description',
                                      subtitle: 'Optional',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _descriptionController,
                                      maxLines: 4,
                                      textInputAction: TextInputAction.newline,
                                      decoration: _fieldDecoration(
                                        theme,
                                        hintText:
                                            'Tell us what happened in a few words.',
                                      ),
                                    ),
                                  ] else ...[
                                    _SectionHeader(
                                      title: 'Where did this happen',
                                      subtitle: 'Required',
                                    ),
                                    const SizedBox(height: 8),
                                    _SearchSelectField(
                                      label: 'Choose location type',
                                      value: _exchangeLocationType,
                                      options: _exchangeLocationTypes,
                                      searchHint: 'Search location type',
                                      onSelected: (value) => setState(
                                          () => _exchangeLocationType = value),
                                    ),
                                    const SizedBox(height: 14),
                                    _SectionHeader(
                                      title: 'Business name',
                                      subtitle: 'Optional',
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _businessController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: _fieldDecoration(
                                        theme,
                                        hintText: 'Optional business or agent',
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: _busy ? null : _submit,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _busy
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              'Submit',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ComplaintConfirmationView extends StatelessWidget {
  const _ComplaintConfirmationView({
    super.key,
    required this.referenceNumber,
    required this.onCopy,
    required this.onDone,
  });

  final String referenceNumber;
  final VoidCallback onCopy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 10),
              Icon(
                Icons.verified_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                'Complaint registered',
                style: theme.textTheme.headlineLg.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                referenceNumber,
                style: theme.textTheme.headlineMd.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The Consumer Protection Commission will review this report.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMd.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: onCopy,
                  child: const Text('Copy reference'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(ThemeData theme, {required String hintText}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerLowest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.labelMd.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.labelMd.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SearchSelectField extends StatelessWidget {
  const _SearchSelectField({
    required this.label,
    required this.value,
    required this.options,
    required this.searchHint,
    required this.onSelected,
  });

  final String label;
  final String? value;
  final List<String> options;
  final String searchHint;
  final ValueChanged<String> onSelected;

  Future<void> _openSelector(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchSelectorSheet(
        title: label,
        searchHint: searchHint,
        options: options,
        selected: value,
      ),
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = value == null || value!.isEmpty ? label : value!;
    return InkWell(
      onTap: () => _openSelector(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayValue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLg.copyWith(
                  fontWeight: value == null ? FontWeight.w600 : FontWeight.w800,
                  color: value == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.keyboard_arrow_down,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SearchSelectorSheet extends StatefulWidget {
  const _SearchSelectorSheet({
    required this.title,
    required this.searchHint,
    required this.options,
    required this.selected,
  });

  final String title;
  final String searchHint;
  final List<String> options;
  final String? selected;

  @override
  State<_SearchSelectorSheet> createState() => _SearchSelectorSheetState();
}

class _SearchSelectorSheetState extends State<_SearchSelectorSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    final scored = widget.options
        .map((item) => MapEntry(item, _fuzzyScore(item, query)))
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) {
        final byScore = b.value.compareTo(a.value);
        if (byScore != 0) return byScore;
        return a.key.compareTo(b.key);
      });
    return scored.map((entry) => entry.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.56,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                children: [
                  _SheetHandle(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.headlineMd.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final option = _filtered[index];
                        final selected = option == widget.selected;
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(option),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              option,
                              style: theme.textTheme.bodyLg.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

double _fuzzyScore(String haystack, String query) {
  final text = haystack.toLowerCase();
  if (text.contains(query)) return 1000.0 - text.indexOf(query).toDouble();
  var score = 0;
  var lastIndex = -1;
  for (final char in query.split('')) {
    final index = text.indexOf(char, lastIndex + 1);
    if (index < 0) return 0;
    score += 10 - (index - lastIndex - 1).clamp(0, 10);
    lastIndex = index;
  }
  return score.toDouble();
}

final List<String> _zimTowns = <String>[
  'Beitbridge',
  'Binga',
  'Bindura',
  'Bikita',
  'Bulawayo',
  'Bubi',
  'Centenary',
  'Chegutu',
  'Chimanimani',
  'Chinhoyi',
  'Chipinge',
  'Chiredzi',
  'Chivhu',
  'Concession',
  'Darwendale',
  'Esigodini',
  'Gokwe',
  'Gwanda',
  'Gweru',
  'Harare',
  'Hwange',
  'Insiza',
  'Kadoma',
  'Kariba',
  'Karoi',
  'Kezi',
  'Kwekwe',
  'Lupane',
  'Lundi',
  'Macheke',
  'Makaha',
  'Mberengwa',
  'Marondera',
  'Masvingo',
  'Matobo',
  'Mazowe',
  'Mhangura',
  'Mt Darwin',
  'Mvurwi',
  'Mutare',
  'Murehwa',
  'Mushumbi Pools',
  'Mutoko',
  'Mvuma',
  'Norton',
  'Nyanga',
  'Nkayi',
  'Nyamandlovu',
  'Plumtree',
  'Redcliff',
  'Rushinga',
  'Rusape',
  'Ruwa',
  'Shamva',
  'Shurugwi',
  'Seke',
  'St Alberts',
  'Zaka',
  'Zhombe',
  'Tsholotsho',
  'Victoria Falls',
  'Wedza',
  'West Nicholson',
  'Zvishavane',
]..sort();

final List<String> _commonGoods = <String>[
  'Airtime',
  'Avocados',
  'Baby formula',
  'Apples',
  'Bananas',
  'Beans',
  'Beef',
  'Biscuits',
  'Butter',
  'Bread',
  'Batteries',
  'Cabbage',
  'Cement',
  'Chicken',
  'Cooking gas',
  'Cooking oil',
  'Cornflakes',
  'Cookies',
  'Cooking salt',
  'Cups',
  'Detergent',
  'Dishwashing liquid',
  'Diapers',
  'Eggs',
  'Face soap',
  'Fish',
  'Flour',
  'Fuel',
  'Fruits',
  'Fuel coupon',
  'Garlic',
  'Garri',
  'Grapes',
  'Groceries',
  'Groundnuts',
  'Instant coffee',
  'Ice cream',
  'Iron sheets',
  'Jam',
  'Laundry soap',
  'Laptop',
  'Lemons',
  'Maize',
  'Maize meal',
  'Matches',
  'Milk',
  'Mop',
  'Nappies',
  'Onions',
  'Orange juice',
  'Oranges',
  'Peanut butter',
  'Petrol',
  'Phone',
  'Phone charger',
  'Pork',
  'Potatoes',
  'Rice',
  'Salt',
  'School shoes',
  'School uniform',
  'Sacks',
  'Soda',
  'Soap',
  'Sugar',
  'Sweets',
  'Stationery',
  'Toilet paper',
  'Toothpaste',
  'Tomatoes',
  'Vegetable oil',
  'Vegetables',
  'Yoghurt',
  'Water',
]..sort();

const List<String> _exchangeLocationTypes = <String>[
  'Bank',
  'Bureau de change',
  'Fuel station',
  'Mobile money agent',
  'Shop or supermarket',
  'Street money changer',
  'Other',
];

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
    final background = switch (result.kind) {
      VerdictKind.fair => const Color(0xFFEAF9EC),
      VerdictKind.overcharged => const Color(0xFFF8F9FA),
      VerdictKind.undervalued => const Color(0xFFFFF4D6),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _ComparisonRow(
            label: 'Fair price',
            value: formatCurrencyAmount(to, fair),
            valueColor: textColor,
            boldLabel: true,
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.black.withOpacity(0.1)),
          const SizedBox(height: 14),
          _ComparisonRow(
            label: 'Shop price',
            value: formatCurrencyAmount(to, result.askedToPay),
            valueColor: textColor,
            labelTrailing: result.kind == VerdictKind.fair
                ? Icons.check_circle_outline
                : Icons.trending_up,
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
    this.boldLabel = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData? labelTrailing;
  final bool boldLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMd.copyWith(
                        color: valueColor,
                        letterSpacing: 1.0,
                        fontWeight:
                            boldLabel ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (labelTrailing != null) ...[
                    const SizedBox(width: 6),
                    Icon(labelTrailing, size: 16, color: valueColor),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.statLg.copyWith(
                    color: valueColor,
                    fontSize: 32,
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
