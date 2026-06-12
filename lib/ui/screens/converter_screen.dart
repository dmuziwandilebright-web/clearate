import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _amountController = TextEditingController();
  Currency _from = Currency.usd;
  Currency _to = Currency.zar;

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = AppScope.of(context).ratesController.state.snapshot;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final rate = snapshot == null ? null : snapshot.rate(_from, _to);
    final converted = rate == null || rate <= 0 ? null : amount * rate;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width <= 360 || size.height <= 800;
    final wide = size.width >= 720;
    final topPadding = compact ? 6.0 : 12.0;
    final titleGap = compact ? 1.0 : 4.0;
    final sectionGap = compact ? 8.0 : 18.0;
    final panelGap = compact ? 6.0 : 12.0;
    final bottomGap = compact ? 10.0 : 18.0;
    final panelPadding = compact ? 8.0 : 14.0;
    final panelHeight = compact ? 85.0 : (wide ? 112.0 : 124.0);
    final swapSize = compact ? 34.0 : (wide ? 38.0 : 40.0);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget buildPanels() {
            if (wide) {
              return SizedBox(
                height: panelHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _AmountPanel(
                            label: 'Money You Have',
                            currency: _from,
                            amountController: _amountController,
                            onAmountChanged: (_) => setState(() {}),
                            amountText: _amountController.text,
                            amountColor: theme.colorScheme.primary,
                            compact: compact,
                            panelPadding: panelPadding,
                            onCurrencyChanged: (value) =>
                                setState(() => _from = value),
                          ),
                        ),
                        SizedBox(width: panelGap),
                        Expanded(
                          child: _AmountPanel(
                            label: 'Money You Get',
                            currency: _to,
                            amountText: converted == null
                                ? '---'
                                : formatMoney(converted),
                            amountColor: theme.colorScheme.onSurface,
                            filled: true,
                            compact: compact,
                            panelPadding: panelPadding,
                            onCurrencyChanged: (value) =>
                                setState(() => _to = value),
                          ),
                        ),
                      ],
                    ),
                    _SwapButton(
                      size: swapSize,
                      onTap: _swap,
                    ),
                  ],
                ),
              );
            }

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: panelHeight,
                      child: _AmountPanel(
                        label: 'Money You Have',
                        currency: _from,
                        amountController: _amountController,
                        onAmountChanged: (_) => setState(() {}),
                        amountText: _amountController.text,
                        amountColor: theme.colorScheme.primary,
                        compact: compact,
                        panelPadding: panelPadding,
                        onCurrencyChanged: (value) =>
                            setState(() => _from = value),
                      ),
                    ),
                    SizedBox(height: panelGap),
                    SizedBox(
                      height: panelHeight,
                      child: _AmountPanel(
                        label: 'Money You Get',
                        currency: _to,
                        amountText:
                            converted == null ? '---' : formatMoney(converted),
                        amountColor: theme.colorScheme.onSurface,
                        filled: true,
                        compact: compact,
                        panelPadding: panelPadding,
                        onCurrencyChanged: (value) =>
                            setState(() => _to = value),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: panelHeight - (swapSize / 2) + (panelGap / 2),
                  child: _SwapButton(
                    size: swapSize,
                    onTap: _swap,
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomGap),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Currency Converter',
                    style: theme.textTheme.headlineLgMobile.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 24 : null,
                    ),
                  ),
                  SizedBox(height: titleGap),
                  if (!compact)
                    Text(
                      'Instant, accurate exchange calculations.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMd.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  SizedBox(height: sectionGap),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: buildPanels()),
                      ],
                    )
                  else
                    buildPanels(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({
    required this.label,
    required this.currency,
    this.amountController,
    this.onAmountChanged,
    required this.amountText,
    required this.amountColor,
    required this.onCurrencyChanged,
    required this.compact,
    required this.panelPadding,
    this.filled = false,
  });

  final String label;
  final Currency currency;
  final TextEditingController? amountController;
  final ValueChanged<String>? onAmountChanged;
  final String amountText;
  final Color amountColor;
  final ValueChanged<Currency> onCurrencyChanged;
  final bool compact;
  final double panelPadding;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(panelPadding),
      decoration: BoxDecoration(
        color: filled
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMd.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11 : 13,
                  ),
                ),
              ),
              _CurrencyMenu(
                  currency: currency,
                  compact: compact,
                  onChanged: onCurrencyChanged),
            ],
          ),
          SizedBox(height: compact ? 2 : 6),
          Row(
            children: [
              Expanded(
                child: amountController == null
                    ? Text(
                        amountText,
                        style: theme.textTheme.displayLg.copyWith(
                          color: amountColor,
                          fontSize: compact
                              ? (label == 'Money You Have' ? 26 : 24)
                              : (label == 'Money You Have' ? 36 : 34),
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                        ],
                        cursorColor: amountColor,
                        style: theme.textTheme.displayLg.copyWith(
                          color: amountColor,
                          fontSize: compact
                              ? (label == 'Money You Have' ? 26 : 24)
                              : (label == 'Money You Have' ? 36 : 34),
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: '0.00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: onAmountChanged,
                      ),
              ),
              Container(
                width: compact ? 3 : 4,
                height: compact ? 18 : 30,
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
    required this.compact,
    required this.onChanged,
  });

  final Currency currency;
  final bool compact;
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
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 13, vertical: compact ? 7 : 9),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.uiLabel,
              style: theme.textTheme.labelMd.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                fontSize: compact ? 12 : 14,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down,
                color: theme.colorScheme.onSurfaceVariant,
                size: compact ? 18 : 20),
          ],
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onTap, required this.size});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.swap_vert,
            color: Colors.white,
            size: size * 0.48,
          ),
        ),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.size,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.destructive = false,
    this.compact = false,
  });

  final double size;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool destructive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: destructive
                ? const Color(0xFFFFDAD6)
                : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: const [],
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(compact ? 2.5 : 3.5),
            child: label == '⌫'
                ? Icon(Icons.backspace_outlined,
                    color: theme.colorScheme.error, size: compact ? 16 : 18)
                : Text(
                    label,
                    style: theme.textTheme.headlineMd.copyWith(
                      color: destructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                      fontSize: compact ? 20 : 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
