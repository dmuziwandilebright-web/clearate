import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../domain/currency.dart';
import '../formatters.dart';
import '../theme.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  Currency _from = Currency.usd;
  Currency _to = Currency.zwg;
  String _input = '0';

  void _append(String v) {
    setState(() {
      if (_input == '0' && v != '.') {
        _input = v;
      } else {
        if (v == '.' && _input.contains('.')) return;
        if (_input.length >= 9) return;
        _input += v;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_input.isEmpty || _input == '0') return;
      _input = _input.substring(0, _input.length - 1);
      if (_input.isEmpty) _input = '0';
    });
  }

  void _preset(double amount) {
    setState(() => _input = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2));
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = AppScope.of(context).ratesController.state.snapshot;

    final fromAmount = double.tryParse(_input) ?? 0;
    final rate = snapshot == null ? null : snapshot.rate(_from, _to);
    final converted = rate == null ? null : fromAmount * rate;

    // Symbol for quick amounts
    final symbol = switch (_from) {
      Currency.usd => '\$',
      Currency.zar => 'R',
      Currency.zwg => 'ZiG ',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Currency Converter',
          style: theme.textTheme.headlineLgMobile.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Instant, accurate exchange calculations.',
          style: theme.textTheme.bodyMd.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        // Stack to overlap the Swap Button between From and To Cards
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                // From Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'From',
                            style: theme.textTheme.labelMd.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          _buildCurrencyDropdown(_from, (c) => setState(() => _from = c), theme),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _input,
                              style: theme.textTheme.statLg.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Pulsing indicator cursor
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Gap between cards
                // To Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'To',
                            style: theme.textTheme.labelMd.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          _buildCurrencyDropdown(_to, (c) => setState(() => _to = c), theme),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        converted == null ? '0.00' : formatMoney(converted),
                        style: theme.textTheme.statLg.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Swap Button positioned right in the middle
            Positioned(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _swap,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.swap_vert,
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Preset Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPresetButton('$symbol\u200B5', 5, theme),
            const SizedBox(width: 8),
            _buildPresetButton('$symbol\u200B10', 10, theme),
            const SizedBox(width: 8),
            _buildPresetButton('$symbol\u200B20', 20, theme),
            const SizedBox(width: 8),
            _buildPresetButton('$symbol\u200B50', 50, theme),
            const SizedBox(width: 8),
            _buildPresetButton('$symbol\u200B100', 100, theme),
          ],
        ),
        const SizedBox(height: 20),
        // Keypad
        _buildKeypad(theme),
        const SizedBox(height: 24),
        // Disclaimer / Footer
        Center(
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Powered by Today's Official Rates",
                    style: theme.textTheme.labelMd.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                snapshot == null
                    ? 'Rates are updated every 60 seconds from centralized bank feeds.'
                    : 'Last updated ${formatHonestUpdated(snapshot.fetchedAt)}. Clearate does not provide brokerage services.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCurrencyDropdown(Currency value, ValueChanged<Currency> onChanged, ThemeData theme) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Currency>(
        value: value,
        icon: Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.primary,
        ),
        style: theme.textTheme.headlineMd.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        items: Currency.values
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.uiLabel),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _buildPresetButton(String label, double amount, ThemeData theme) {
    return Expanded(
      child: SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: () => _preset(amount),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(color: theme.colorScheme.outline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMd.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    Widget key(String label, {VoidCallback? onTap}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 1,
                backgroundColor: theme.colorScheme.surfaceContainerLowest,
                foregroundColor: theme.colorScheme.primary,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onTap,
              child: Text(
                label,
                style: theme.textTheme.headlineMd.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget backspaceKey(VoidCallback onTap) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 1,
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onTap,
              child: const Icon(Icons.backspace_outlined, size: 20),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              key('1', onTap: () => _append('1')),
              key('2', onTap: () => _append('2')),
              key('3', onTap: () => _append('3')),
            ],
          ),
          Row(
            children: [
              key('4', onTap: () => _append('4')),
              key('5', onTap: () => _append('5')),
              key('6', onTap: () => _append('6')),
            ],
          ),
          Row(
            children: [
              key('7', onTap: () => _append('7')),
              key('8', onTap: () => _append('8')),
              key('9', onTap: () => _append('9')),
            ],
          ),
          Row(
            children: [
              key('.', onTap: () => _append('.')),
              key('0', onTap: () => _append('0')),
              backspaceKey(_backspace),
            ],
          ),
        ],
      ),
    );
  }
}
