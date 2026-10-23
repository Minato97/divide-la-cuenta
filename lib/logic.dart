import 'dart:math';

class EqualResult {
  const EqualResult({
    required this.bill,
    required this.tip,
    required this.total,
    required this.perPerson,
    required this.people,
  });

  final double bill;
  final double tip;
  final double total;
  final double perPerson;
  final int people;
}

/// Divide la cuenta en partes iguales. Con [roundUp] cada persona paga el
/// siguiente peso entero y la diferencia se suma a la propina.
EqualResult splitEqual({
  required double bill,
  required double tipPercent,
  required int people,
  bool roundUp = false,
}) {
  final n = max(1, people);
  final tip = bill * tipPercent / 100;
  final total = bill + tip;
  var per = total / n;
  var realTotal = total;
  var realTip = tip;
  if (roundUp) {
    per = (per - 1e-9).ceilToDouble();
    realTotal = per * n;
    realTip = realTotal - bill;
  }
  return EqualResult(
    bill: bill,
    tip: realTip,
    total: realTotal,
    perPerson: per,
    people: n,
  );
}

class Item {
  Item(this.name, this.amount, this.sharedBy);

  final String name;
  final double amount;
  final Set<int> sharedBy;
}

class PersonShare {
  const PersonShare(this.name, this.consumed, this.tip);

  final String name;
  final double consumed;
  final double tip;
  double get total => consumed + tip;
}

/// Reparte cada plato entre quienes lo comparten y la propina en proporción.
List<PersonShare> splitByItems({
  required List<String> people,
  required List<Item> items,
  required double tipPercent,
}) {
  final consumed = List<double>.filled(people.length, 0);
  for (final it in items) {
    final who = it.sharedBy.where((i) => i >= 0 && i < people.length).toList();
    if (who.isEmpty) continue;
    final part = it.amount / who.length;
    for (final i in who) {
      consumed[i] += part;
    }
  }
  return [
    for (var i = 0; i < people.length; i++)
      PersonShare(people[i], consumed[i], consumed[i] * tipPercent / 100),
  ];
}

String money(double v, {int decimals = 2}) {
  final fixed = v.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final dec = parts.length > 1 ? '.${parts[1]}' : '';
  return '${v < 0 ? '-' : ''}\$$intPart$dec';
}

double parseNumber(String s) =>
    double.tryParse(s.replaceAll(',', '').replaceAll('\$', '').trim()) ?? 0;
