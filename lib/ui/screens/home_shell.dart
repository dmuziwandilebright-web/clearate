import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../config/brand_assets.dart';
import '../../state/rates_controller.dart';
import '../theme.dart';
import 'converter_screen.dart';
import 'more_screen.dart';
import 'rates_screen.dart';
import 'verdict_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const _tabs = <Widget>[
    RatesScreen(),
    VerdictScreen(),
    ConverterScreen(),
    MoreScreen(),
  ];

  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _reloadFromStorage() async {
    await AppScope.of(context).ratesController.restoreFromStorage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reloadFromStorage());
    }
  }

  void _showWarmSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFFF5EA),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF6D3A00),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _refreshRates() async {
    final result =
        await AppScope.of(context).ratesController.refreshIfAllowed();
    if (!mounted) return;

    if (result == RatesRefreshResult.refreshed) {
      _showWarmSnack('Rates refreshed. You are now on the latest rates.');
    } else if (result == RatesRefreshResult.alreadyFresh) {
      _showWarmSnack(
        'You already have the latest rates. We will check again after 24 hours.',
      );
    } else if (result == RatesRefreshResult.rejected) {
      _showWarmSnack(
        'That update looked unusual, so we kept your saved rates.',
      );
    } else {
      _showWarmSnack(
        'Could not refresh right now. We kept your saved rates safely.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        toolbarHeight: 56,
        titleSpacing: 16,
        title: const _BrandTitle(),
        actions: [
          IconButton(
            onPressed: _refreshRates,
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh rates',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Stack(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                IgnorePointer(
                  ignoring: i != _index,
                  child: AnimatedOpacity(
                    opacity: i == _index ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: TickerMode(
                      enabled: i == _index,
                      child: _tabs[i],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _BrandMark(),
        const SizedBox(width: 10),
        Text(
          'Clearate',
          style: Theme.of(context).textTheme.headlineMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        BrandAssets.appLogo,
        width: 24,
        height: 24,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.trending_up,
              label: 'Rates',
              selected: index == 0,
              onTap: () => onChanged(0),
            ),
            _NavItem(
              icon: Icons.gavel,
              label: 'Price Check',
              selected: index == 1,
              onTap: () => onChanged(1),
            ),
            _NavItem(
              icon: Icons.currency_exchange,
              label: 'Converter',
              selected: index == 2,
              onTap: () => onChanged(2),
            ),
            _NavItem(
              icon: Icons.more_horiz,
              label: 'More',
              selected: index == 3,
              onTap: () => onChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.secondaryFixed;
    final selectedText = theme.colorScheme.onSecondaryFixed;
    final unselectedText = theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? selectedText : unselectedText,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelMd.copyWith(
                  color: selected ? selectedText : unselectedText,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 11.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
