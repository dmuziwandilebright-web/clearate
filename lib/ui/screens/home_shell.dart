import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
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

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        titleSpacing: 16,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Clearate',
              style: theme.textTheme.headlineMd.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => AppScope.of(context).ratesController.forceRefresh(),
            icon: Icon(
              Icons.sync,
              color: theme.colorScheme.onPrimary,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          RatesScreen(),
          VerdictScreen(),
          ConverterScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.trending_up, 'Rates', theme),
            _buildNavItem(1, Icons.gavel, 'Price Check', theme),
            _buildNavItem(2, Icons.currency_exchange, 'Converter', theme),
            _buildNavItem(3, Icons.more_horiz, 'More', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ThemeData theme) {
    final isSelected = _index == index;

    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.secondaryFixed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.onSecondaryFixed : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelMd.copyWith(
                color: isSelected ? theme.colorScheme.onSecondaryFixed : theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
