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
  Currency _to = Currency.zar;
  String _input = '0';

  void _append(String value) {
    setState(() {
      if (_input == '0' && value != '.') {
        _input = value;
        return;
      }
      if (value == '.' && _input.contains('.')) return;
      if (_input.length >= 12) return;
      _input += value;
    });
  }

  void _backspace() {
    setState(() {
      if (_input == '0') return;
      if (_input.length == 1) {
        _input = '0';
        return;
      }
      _input = _input.substring(0, _input.length - 1);
      if (_input.isEmpty || _input == '-') _input = '0';
    });
  }

  void _clear() {
    setState(() => _input = '0');
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
    final amount = double.tryParse(_input) ?? 0;
    final rate = snapshot == null ? null : snapshot.rate(_from, _to);
    final converted = rate == null || rate <= 0 ? null : amount * rate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
        const SizedBox(height: 18),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Column(
              children: [
                _AmountPanel(
                  label: 'Money You Have',
                  currency: _from,
                  amountText: _input,
                  amountColor: theme.colorScheme.primary,
                  onCurrencyChanged: (value) => setState(() => _from = value),
                ),
                const SizedBox(height: 12),
                _AmountPanel(
                  label: 'Money You Get',
                  currency: _to,
                  amountText: converted == null ? '---' : formatMoney(converted),
                  amountColor: theme.colorScheme.onSurface,
                  filled: true,
                  onCurrencyChanged: (value) => setState(() => _to = value),
                ),
              ],
            ),
            Positioned(
              top: 86,
              child: _SwapButton(onTap: _swap),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.22,
            children: [
              for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0'])
                _KeypadKey(
                  label: key,
                  onTap: () => _append(key),
                ),
              _KeypadKey(
                label: '⌫',
                destructive: true,
                onTap: _backspace,
                onLongPress: _clear,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({
    required this.label,
    required this.currency,
    required this.amountText,
    required this.amountColor,
    required this.onCurrencyChanged,
    this.filled = false,
  });

  final String label;
  final Currency currency;
  final String amountText;
  final Color amountColor;
  final ValueChanged<Currency> onCurrencyChanged;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: filled ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMd.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _CurrencyMenu(currency: currency, onChanged: onCurrencyChanged),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  amountText,
                  style: theme.textTheme.displayLg.copyWith(
                    color: amountColor,
                    fontSize: label == 'Money You Have' ? 38 : 36,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 4,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyMenu extends StatelessWidget {
  const _CurrencyMenu({
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
      child: Row(
        children: [
          Text(
            currency.uiLabel,
            style: theme.textTheme.headlineMd.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant, size: 22),
        ],
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.swap_vert, color: Colors.white),
        ),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: destructive ? const Color(0xFFFFDAD6) : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: label == '⌫'
            ? Icon(Icons.backspace_outlined, color: theme.colorScheme.error)
            : Text(
                label,
                style: theme.textTheme.headlineMd.copyWith(
                  color: destructive ? theme.colorScheme.error : theme.colorScheme.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
