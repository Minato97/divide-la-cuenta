import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads.dart';
import 'logic.dart';
import 'widgets.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final List<String> _people = ['Ana', 'Beto', 'Carla'];
  final List<Item> _items = [
    Item('Pizza', 260, {0, 1, 2}),
    Item('Pasta', 180, {0}),
    Item('Hamburguesa', 150, {1}),
    Item('Ensalada', 120, {2}),
    Item('Bebidas', 240, {0, 1, 2}),
  ];
  double _tip = 10;

  Future<void> _addPerson() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva persona'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: fieldDecoration('Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && _people.length < 20) {
      setState(() => _people.add(name));
    }
  }

  void _removePerson(int i) {
    setState(() {
      _people.removeAt(i);
      for (final it in _items) {
        final shifted = {
          for (final k in it.sharedBy)
            if (k != i) k > i ? k - 1 : k,
        };
        it.sharedBy
          ..clear()
          ..addAll(shifted);
      }
    });
  }

  Future<void> _addItem() async {
    if (_people.isEmpty) return;
    final name = TextEditingController();
    final amount = TextEditingController();
    final who = <int>{for (var i = 0; i < _people.length; i++) i};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Nuevo platillo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: fieldDecoration('Platillo o bebida'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: fieldDecoration('Precio', suffix: 'MXN'),
                ),
                const SizedBox(height: 12),
                const Text('¿Quién lo comparte?'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var i = 0; i < _people.length; i++)
                      FilterChip(
                        label: Text(_people[i]),
                        selected: who.contains(i),
                        onSelected: (v) =>
                            setD(() => v ? who.add(i) : who.remove(i)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    final value = parseNumber(amount.text);
    if (ok == true && value > 0 && who.isNotEmpty) {
      setState(
        () => _items.add(
          Item(
            name.text.trim().isEmpty ? 'Platillo' : name.text.trim(),
            value,
            who,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shares = splitByItems(
      people: _people,
      items: _items,
      tipPercent: _tip,
    );
    final grand = shares.fold<double>(0, (s, p) => s + p.total);
    final maxTotal = shares.fold<double>(
      0,
      (m, p) => p.total > m ? p.total : m,
    );
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HeroBanner(
          title: 'Cada quien lo suyo',
          subtitle: 'Asigna platillos y paga solo lo que consumiste.',
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Personas',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _people.length; i++)
                InputChip(
                  avatar: CircleAvatar(
                    child: Text(_people[i].characters.first.toUpperCase()),
                  ),
                  label: Text(_people[i]),
                  onDeleted: () => _removePerson(i),
                ),
              ActionChip(
                avatar: const Icon(Icons.person_add, size: 18),
                label: const Text('Agregar'),
                onPressed: _addPerson,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Platillos',
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(_items[i].name),
                  subtitle: Text(
                    _items[i].sharedBy.isEmpty
                        ? 'Sin asignar'
                        : (_items[i].sharedBy.toList()..sort())
                              .where((k) => k < _people.length)
                              .map((k) => _people[k])
                              .join(', '),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        money(_items[i].amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _items.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar platillo'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Propina',
          child: Wrap(
            spacing: 8,
            children: [
              for (final p in const [0.0, 10.0, 15.0, 20.0])
                ChoiceChip(
                  label: Text('${p.toInt()}%'),
                  selected: _tip == p,
                  onSelected: (_) => setState(() => _tip = p),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Cada quien paga',
          child: Column(
            children: [
              for (final p in shares)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            money(p.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: maxTotal == 0 ? 0 : p.total / maxTotal,
                          minHeight: 10,
                          color: kGreen,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  const Expanded(child: Text('Total con propina')),
                  Text(
                    money(grand),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: [
                  for (final p in shares) '${p.name}: ${money(p.total)}',
                  'Total: ${money(grand)}',
                ].join('\n'),
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
