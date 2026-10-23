import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads.dart';
import 'logic.dart';
import 'widgets.dart';

class EqualPage extends StatefulWidget {
  const EqualPage({super.key});

  @override
  State<EqualPage> createState() => _EqualPageState();
}

class _EqualPageState extends State<EqualPage> {
  final _bill = TextEditingController(text: '1200');
  final _custom = TextEditingController();
  double _tip = 10;
  int _people = 4;
  bool _roundUp = false;

  @override
  void dispose() {
    _bill.dispose();
    _custom.dispose();
    super.dispose();
  }

  void _setTip(double v) => setState(() {
    _tip = v;
    _custom.clear();
  });

  @override
  Widget build(BuildContext context) {
    final r = splitEqual(
      bill: parseNumber(_bill.text),
      tipPercent: _tip,
      people: _people,
      roundUp: _roundUp,
    );
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HeroBanner(
          title: 'Cuentas claras',
          subtitle: 'Divide la cuenta y la propina en segundos.',
        ),
        const SizedBox(height: 16),
        Section(
          title: 'La cuenta',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _bill,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: fieldDecoration(
                  'Total de la cuenta',
                  suffix: 'MXN',
                  icon: Icons.receipt_long,
                ),
              ),
              const SizedBox(height: 16),
              Text('Propina', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in const [0.0, 10.0, 15.0, 20.0])
                    ChoiceChip(
                      label: Text('${p.toInt()}%'),
                      selected: _tip == p && _custom.text.isEmpty,
                      onSelected: (_) => _setTip(p),
                    ),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _custom,
                      onChanged: (v) => setState(() {
                        if (v.isNotEmpty) _tip = parseNumber(v);
                      }),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: fieldDecoration(
                        'Otro',
                        suffix: '%',
                      ).copyWith(isDense: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.group),
                  const SizedBox(width: 10),
                  Text('Personas', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: _people > 1
                        ? () => setState(() => _people--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_people',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _people < 50
                        ? () => setState(() => _people++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Redondear hacia arriba por persona'),
                subtitle: const Text('Cada quien paga un peso entero'),
                value: _roundUp,
                onChanged: (v) => setState(() => _roundUp = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BigResult(
          label: 'Cada persona paga',
          value: money(r.perPerson),
          footnote: '${r.people} ${r.people == 1 ? 'persona' : 'personas'}',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatBox(
                icon: Icons.restaurant,
                label: 'Cuenta',
                value: money(r.bill),
                color: kGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatBox(
                icon: Icons.volunteer_activism,
                label: 'Propina',
                value: money(r.tip),
                color: kGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatBox(
          icon: Icons.payments,
          label: 'Total a pagar',
          value: money(r.total),
          color: kTeal,
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text:
                    'Cuenta ${money(r.bill)} + propina ${money(r.tip)} = ${money(r.total)}. '
                    'Entre ${r.people}: ${money(r.perPerson)} cada uno.',
              ),
            );
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Resumen copiado')));
            AdService.instance.maybeShowInterstitial(every: 4);
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copiar resumen'),
        ),
      ],
    );
  }
}
