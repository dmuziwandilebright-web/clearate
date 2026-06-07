import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/app_scope.dart';
import '../../domain/currency.dart';
import '../../domain/rate_snapshot.dart';
import '../formatters.dart';
import '../theme.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).ratesController.refreshIfAllowed();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).ratesController;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.state.snapshot;
        final previous = controller.previousSnapshot;
        final warning = controller.state.warning;
        final isLoading = controller.state.isRefreshing && snapshot == null;

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                Center(
                  child: _LivePill(
                    snapshot: snapshot,
                    isUpdating: controller.state.isRefreshing,
                  ),
                ),
                if (warning != null) ...[
                  const SizedBox(height: 12),
                  _WarningBanner(
                    text: warning,
                    onRetry: controller.forceRefresh,
                  ),
                ],
                const SizedBox(height: 16),
                if (isLoading)
                  ...List.generate(3, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == 2 ? 0 : 16),
                      child: Shimmer(
                        controller: _shimmerController,
                        child: const _RateCardSkeleton(),
                      ),
                    );
                  })
                else if (snapshot == null)
                  _NoRatesState(onRetry: controller.forceRefresh)
                else ...[
                  _RateCard(
                    from: Currency.usd,
                    to: Currency.zwg,
                    snapshot: snapshot,
                    previous: previous,
                  ),
                  const SizedBox(height: 16),
                  _RateCard(
                    from: Currency.usd,
                    to: Currency.zar,
                    snapshot: snapshot,
                    previous: previous,
                  ),
                  const SizedBox(height: 16),
                  _RateCard(
                    from: Currency.zar,
                    to: Currency.zwg,
                    snapshot: snapshot,
                    previous: previous,
                  ),
                  if (snapshot.bwpUsd > 0) ...[
                    const SizedBox(height: 16),
                    _RateCard(
                      from: Currency.usd,
                      to: Currency.bwp,
                      snapshot: snapshot,
                      previous: previous,
                    ),
                  ],
                ],
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _RatesActionBar(
                  showQrEnabled: snapshot != null && !controller.state.isRefreshing,
                  scanEnabled: !controller.state.isRefreshing,
                  onShowQr: snapshot == null ? null : () => _showQrDialog(context, snapshot),
                  onScan: () => _showScannerDialog(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showQrDialog(BuildContext context, RateSnapshot snapshot) async {
    final text = jsonEncode(snapshot.toJson());
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close QR preview',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Share Rates',
                            style: Theme.of(context).textTheme.headlineMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: QrImageView(
                            data: text,
                            version: QrVersions.auto,
                            padding: const EdgeInsets.all(10),
                            gapless: false,
                            backgroundColor: Colors.white,
                            errorStateBuilder: (context, error) => Center(
                              child: Text(
                                'Could not build QR',
                                style: Theme.of(context).textTheme.bodyMd,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Let others scan this code to get current exchange rates instantly.',
                        style: Theme.of(context).textTheme.bodyMd.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  Future<void> _showScannerDialog(BuildContext context) async {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    final currentSnapshot = AppScope.of(context).ratesController.state.snapshot;
    var handled = false;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close scanner',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: StatefulBuilder(
              builder: (context, _) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await controller.stop();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            label: const Text('Cancel', style: TextStyle(color: Colors.white)),
                          ),
                          const Spacer(),
                          Text(
                            'Scanning...',
                            style: theme.textTheme.labelMd.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 92),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: MobileScanner(
                              controller: controller,
                              onDetect: (capture) async {
                                if (handled) return;
                                final barcode = capture.barcodes.isEmpty ? null : capture.barcodes.first;
                                final raw = barcode?.rawValue;
                                if (raw == null || raw.isEmpty) {
                                  return;
                                }
                                try {
                                  final imported = RateSnapshot.fromJson(
                                    (jsonDecode(raw) as Map).cast<String, Object?>(),
                                  ).copyWithFetchedAt(DateTime.now());
                                  final current = currentSnapshot;
                                  if (current != null && current.serverTime != null) {
                                    final importedIsOlder = imported.serverTime == null ||
                                        imported.serverTime!.isBefore(current.serverTime!);
                                    if (importedIsOlder) {
                                      handled = true;
                                      await controller.stop();
                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Your rates are already up to date. Show your QR code to the other person instead.'),
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  handled = true;
                                  await AppScope.of(context).ratesController.importSnapshot(imported);
                                  if (!context.mounted) return;
                                  await controller.stop();
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Rates updated from nearby device.')),
                                  );
                                } catch (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("This doesn't look like a Clearate rate code. Try again.")),
                                  );
                                }
                              },
                            ),
                          ),
                          Container(color: Colors.black.withOpacity(0.18)),
                          Center(
                            child: Container(
                              width: 264,
                              height: 264,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white24, width: 2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: const [
                                  _Corner(top: true, left: true),
                                  _Corner(top: true, left: false),
                                  _Corner(top: false, left: true),
                                  _Corner(top: false, left: false),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 140,
                            child: Column(
                              children: [
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryFixed,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Point your camera at another Clearate user\'s QR code.',
                                  style: theme.textTheme.bodyMd.copyWith(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
    await controller.stop();
    controller.dispose();
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({
    required this.snapshot,
    required this.isUpdating,
  });

  final RateSnapshot? snapshot;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (snapshot != null && snapshot!.serverTime == null) ...[
            Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
          ] else ...[
            _PillDot(updating: isUpdating),
            const SizedBox(width: 8),
          ],
          Text(
            snapshot == null
                ? 'Updating rates...'
                : snapshot!.serverTime == null
                    ? "Showing reference rates — connect to get today's live rates"
                    : 'Live Rates Updated: ${formatHonestUpdated(snapshot!.fetchedAt)}',
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillDot extends StatefulWidget {
  const _PillDot({required this.updating});

  final bool updating;

  @override
  State<_PillDot> createState() => _PillDotState();
}

class _PillDotState extends State<_PillDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.updating) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = 0.8 + (_controller.value * 0.4);
        return Container(
          width: 12,
          height: 12,
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(1 - (_controller.value * 0.35)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.text,
    required this.onRetry,
  });

  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0A800).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF6B4E00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMd.copyWith(
                color: const Color(0xFF4E3A00),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _RatesActionBar extends StatelessWidget {
  const _RatesActionBar({
    required this.showQrEnabled,
    required this.scanEnabled,
    required this.onShowQr,
    required this.onScan,
  });

  final bool showQrEnabled;
  final bool scanEnabled;
  final VoidCallback? onShowQr;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: showQrEnabled ? onShowQr : null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.qr_code),
            label: const Text('Show QR'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: scanEnabled ? onScan : null,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan'),
          ),
        ),
      ],
    );
  }
}

class _RateCard extends StatefulWidget {
  const _RateCard({
    required this.from,
    required this.to,
    required this.snapshot,
    required this.previous,
  });

  final Currency from;
  final Currency to;
  final RateSnapshot snapshot;
  final RateSnapshot? previous;

  @override
  State<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<_RateCard> {
  bool _reversed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayFrom = _reversed ? widget.to : widget.from;
    final displayTo = _reversed ? widget.from : widget.to;
    final rate = widget.snapshot.rate(displayFrom, displayTo);
    final inverse = widget.snapshot.rate(displayTo, displayFrom);
    final prevRate = widget.previous == null ? null : widget.previous!.rate(displayFrom, displayTo);
    final delta = (prevRate == null || prevRate <= 0) ? null : ((rate - prevRate) / prevRate) * 100.0;
    final direction = delta == null ? 0 : (delta > 0 ? 1 : -1);
    final deltaText = delta == null
        ? 'Stable'
        : '${delta >= 0 ? '+' : '-'}${delta.abs().toStringAsFixed(1)}% vs yesterday';
    final deltaColor = delta == null
        ? theme.colorScheme.onSurfaceVariant
        : (delta >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C));
    final lastChecked = widget.snapshot.serverTime == null
        ? 'Reference rates'
        : 'Updated: ${formatHonestUpdated(widget.snapshot.fetchedAt)}';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NORMAL BANK RATE',
                        style: theme.textTheme.labelMd.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${displayFrom.uiLabel} to ${displayTo.uiLabel}',
                      style: theme.textTheme.bodyLg.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Sparkline(direction: direction),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '1 ${displayFrom.uiLabel} = ${formatRate(rate)} ${displayTo.uiLabel}',
                  style: theme.textTheme.statLg.copyWith(
                    color: theme.colorScheme.primary,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => setState(() => _reversed = !_reversed),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: _reversed ? 0.5 : 0,
                    child: Icon(
                      Icons.swap_horiz,
                      size: 34,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '1 ${displayTo.uiLabel} = ${formatRate(inverse)} ${displayFrom.uiLabel}',
            style: theme.textTheme.bodyMd.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                delta == null
                    ? Icons.horizontal_rule
                    : (delta >= 0 ? Icons.trending_up : Icons.trending_down),
                size: 18,
                color: deltaColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  deltaText,
                  style: theme.textTheme.labelMd.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                lastChecked,
                style: theme.textTheme.labelMd.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.direction});

  final int direction;

  @override
  Widget build(BuildContext context) {
    final color = direction > 0
        ? const Color(0xFF1B5E20)
        : direction < 0
            ? const Color(0xFFB71C1C)
            : const Color(0xFF505F76);

    return CustomPaint(
      size: const Size(92, 44),
      painter: _SparklinePainter(direction: direction, color: color),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.direction,
    required this.color,
  });

  final int direction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (direction > 0) {
      path.moveTo(0, h * 0.72);
      path.quadraticBezierTo(w * 0.3, h * 0.82, w * 0.58, h * 0.34);
      path.quadraticBezierTo(w * 0.82, h * 0.04, w, h * 0.20);
    } else if (direction < 0) {
      path.moveTo(0, h * 0.22);
      path.quadraticBezierTo(w * 0.26, h * 0.08, w * 0.56, h * 0.56);
      path.quadraticBezierTo(w * 0.82, h * 0.86, w, h * 0.76);
    } else {
      path.moveTo(0, h * 0.44);
      path.quadraticBezierTo(w * 0.28, h * 0.42, w * 0.54, h * 0.40);
      path.quadraticBezierTo(w * 0.78, h * 0.38, w, h * 0.42);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.color != color;
  }
}

class _RateCardSkeleton extends StatelessWidget {
  const _RateCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 258,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ShimmerBlock(width: 132, height: 22, radius: 6),
          const SizedBox(height: 12),
          const _ShimmerBlock(width: 90, height: 16, radius: 6),
          const SizedBox(height: 12),
          const _ShimmerBlock(width: double.infinity, height: 64, radius: 10),
          const SizedBox(height: 10),
          const _ShimmerBlock(width: 120, height: 16, radius: 6),
          const Spacer(),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: const [
              _ShimmerBlock(width: 92, height: 16, radius: 6),
              Spacer(),
              _ShimmerBlock(width: 84, height: 16, radius: 6),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width.isInfinite ? double.infinity : width;
    return Container(
      width: resolvedWidth,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class Shimmer extends StatelessWidget {
  const Shimmer({
    super.key,
    required this.controller,
    required this.child,
  });

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            final x = rect.width * controller.value * 2 - rect.width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xBFFFFFFF),
                Color(0xFFE8E8E8),
              ],
              stops: const [0.25, 0.5, 0.75],
              transform: _SlidingGradientTransform(xOffset: x),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.xOffset});

  final double xOffset;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(xOffset, 0, 0);
  }
}

class _NoRatesState extends StatelessWidget {
  const _NoRatesState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.phone_iphone, size: 38, color: theme.colorScheme.onSurfaceVariant),
                Positioned(
                  right: 16,
                  top: 20,
                  child: Icon(Icons.wifi_off, size: 20, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No rates available yet.',
            style: theme.textTheme.headlineMd.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            "Connect to the internet once to load today's rates. After that the app works offline.",
            style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    required this.top,
    required this.left,
  });

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: top ? BorderSide.none : const BorderSide(color: Colors.white, width: 4),
            left: left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: left ? BorderSide.none : const BorderSide(color: Colors.white, width: 4),
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(12) : Radius.zero,
            topRight: top && !left ? const Radius.circular(12) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(12) : Radius.zero,
            bottomRight: !top && !left ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _PseudoQrPainter extends CustomPainter {
  _PseudoQrPainter(this.data);

  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    const grid = 21;
    final cell = size.shortestSide / grid;
    final paint = Paint()..style = PaintingStyle.fill;
    final hash = data.hashCode.abs();

    bool dark(int x, int y) {
      if (_finder(x, y)) return true;
      final value = (x * 31 + y * 17 + hash) % 7;
      return value <= 2;
    }

    for (var y = 0; y < grid; y++) {
      for (var x = 0; x < grid; x++) {
        final isDark = dark(x, y);
        paint.color = isDark ? Colors.black : Colors.white;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell, cell),
          paint,
        );
      }
    }
  }

  bool _finder(int x, int y) {
    const coords = [
      (0, 0),
      (14, 0),
      (0, 14),
    ];
    for (final (fx, fy) in coords) {
      if (x >= fx && x < fx + 7 && y >= fy && y < fy + 7) {
        final dx = x - fx;
        final dy = y - fy;
        return dx == 0 ||
            dx == 6 ||
            dy == 0 ||
            dy == 6 ||
            (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4);
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _PseudoQrPainter oldDelegate) => oldDelegate.data != data;
}
