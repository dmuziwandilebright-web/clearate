import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../domain/currency.dart';
import '../../domain/rate_snapshot.dart';
import '../formatters.dart';
import '../theme.dart';
import '../widgets/section_card.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).ratesController.refreshIfAllowed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = AppScope.of(context).ratesController;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final snapshot = controller.state.snapshot;
        final previous = controller.previousSnapshot;

        return RefreshIndicator(
          onRefresh: controller.forceRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: _LiveStatusBadge(
                  text: snapshot == null
                      ? 'Live Rates Updated: —'
                      : 'Live Rates Updated: ${formatHonestUpdated(snapshot.fetchedAt)}',
                ),
              ),
              const SizedBox(height: 16),
              if (controller.state.warning != null) ...[
                _WarningBanner(text: controller.state.warning!),
                const SizedBox(height: 16),
              ],
              _RateCard(
                title: 'USD to ZiG',
                from: Currency.usd,
                to: Currency.zwg,
                snapshot: snapshot,
                previous: previous,
              ),
              const SizedBox(height: 16),
              _RateCard(
                title: 'USD to ZAR',
                from: Currency.usd,
                to: Currency.zar,
                snapshot: snapshot,
                previous: previous,
              ),
              const SizedBox(height: 16),
              _RateCard(
                title: 'ZAR to ZiG',
                from: Currency.zar,
                to: Currency.zwg,
                snapshot: snapshot,
                previous: previous,
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(
                    child: _BentoInfoCard(
                      title: 'Financial\nTruth Protocol',
                      icon: Icons.verified_user,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _BentoImageCard(
                      title: 'Market Analysis',
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuBkyOcWnfu94S1UViwNx5hKT5pyFzjOigvzdh3sj8V16GMybWk_cbxYAKOYP4DLRpGGmSy8loibQpiuHrcdC3ZHWfa5TL-3qGcLq9DlCzhRcS8R-j6JvY3EsQvKmyOikyRYtVIEVyzgbwZjsqPXSBRLWzPzIGZqRpiv_1wIdsPzKIzSZSWdv2rtTl1lh0TxRUefLJUnRwDZJhMHtD5PlBUdzrBZ8PvyBXuSBaJ4583yep22IKYj7mNMTR1cCadGmq04qaMhN5SjIUla',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (controller.state.isRefreshing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveStatusBadge extends StatelessWidget {
  const _LiveStatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingDot(),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = theme.colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 12 + (12 * _controller.value),
              height: 12 + (12 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor.withOpacity(0.75 * (1.0 - _controller.value)),
              ),
            );
          },
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.title,
    required this.from,
    required this.to,
    required this.snapshot,
    required this.previous,
  });

  final String title;
  final Currency from;
  final Currency to;
  final RateSnapshot? snapshot;
  final RateSnapshot? previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rate = snapshot == null ? null : snapshot!.rate(from, to);
    final prevRate = previous == null ? null : previous!.rate(from, to);

    final delta = (rate != null && prevRate != null && prevRate > 0)
        ? ((rate - prevRate) / prevRate) * 100.0
        : null;

    final deltaText = delta == null
        ? 'Stable'
        : '${delta >= 0 ? '' : '-'}${formatRate(delta.abs())}% vs yesterday';

    final deltaColor = delta == null
        ? theme.colorScheme.onSurfaceVariant
        : (delta >= 0 ? theme.colorScheme.fairGreen : theme.colorScheme.overchargeRed);

    final direction = delta == null ? 0 : (delta > 0 ? 1 : -1);

    final lastRef = snapshot == null
        ? 'Last Ref: —'
        : 'Last Ref: ${DateTime.now().difference(snapshot!.serverTime).inMinutes.clamp(0, 999)}m ago';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'OFFICIAL RATE',
                  style: theme.textTheme.labelMd.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SparklineWidget(direction: direction),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyLg.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rate == null ? '—' : '1 ${from.uiLabel} = ${formatRate(rate)} ${to.uiLabel}',
            style: theme.textTheme.statLg.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                delta == null
                    ? Icons.horizontal_rule
                    : (delta >= 0 ? Icons.trending_up : Icons.trending_down),
                size: 16,
                color: deltaColor,
              ),
              const SizedBox(width: 6),
              Text(
                deltaText,
                style: theme.textTheme.labelMd.copyWith(
                  color: deltaColor,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                lastRef,
                style: theme.textTheme.labelMd.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SparklineWidget extends StatelessWidget {
  const SparklineWidget({
    super.key,
    required this.direction,
  });

  final int direction;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(80, 36),
      painter: _SparklinePainter(
        direction: direction,
        colorUp: Colors.black,
        colorDown: const Color(0xFFBA1A1A),
        colorStable: const Color(0xFF505F76),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.direction,
    required this.colorUp,
    required this.colorDown,
    required this.colorStable,
  });

  final int direction;
  final Color colorUp;
  final Color colorDown;
  final Color colorStable;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = direction > 0 ? colorUp : (direction < 0 ? colorDown : colorStable)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (direction > 0) {
      path.moveTo(0, h * 0.75);
      path.quadraticBezierTo(w * 0.25, h * 0.875, w * 0.5, h * 0.375);
      path.quadraticBezierTo(w * 0.75, h * 0.125, w, h * 0.25);
    } else if (direction < 0) {
      path.moveTo(0, h * 0.25);
      path.quadraticBezierTo(w * 0.25, h * 0.125, w * 0.5, h * 0.625);
      path.quadraticBezierTo(w * 0.75, h * 0.875, w, h * 0.75);
    } else {
      path.moveTo(0, h * 0.5);
      path.quadraticBezierTo(w * 0.25, h * 0.5, w * 0.5, h * 0.45);
      path.quadraticBezierTo(w * 0.75, h * 0.4, w, h * 0.45);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.direction != direction;
  }
}

class _BentoInfoCard extends StatelessWidget {
  const _BentoInfoCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.primaryContainer,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onPrimaryContainer,
              size: 24,
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.headlineMd.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoImageCard extends StatelessWidget {
  const _BentoImageCard({required this.title, required this.imageUrl});

  final String title;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.surfaceContainer,
                          theme.colorScheme.surfaceDim,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMd.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
