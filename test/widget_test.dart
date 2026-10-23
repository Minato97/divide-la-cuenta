import 'package:divide_cuenta/logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('partes iguales con propina', () {
    final r = splitEqual(bill: 1000, tipPercent: 10, people: 4);
    expect(r.tip, 100);
    expect(r.total, 1100);
    expect(r.perPerson, 275);
  });

  test('redondeo hacia arriba suma la diferencia a la propina', () {
    final r = splitEqual(bill: 1000, tipPercent: 10, people: 3, roundUp: true);
    expect(r.perPerson, 367);
    expect(r.total, 1101);
    expect(r.tip, closeTo(101, 1e-9));
  });

  test('personas mínimo 1', () {
    expect(splitEqual(bill: 100, tipPercent: 0, people: 0).perPerson, 100);
  });

  test('por consumo reparte platillos compartidos y propina', () {
    final s = splitByItems(
      people: ['A', 'B'],
      items: [
        Item('compartido', 100, {0, 1}),
        Item('solo A', 50, {0}),
      ],
      tipPercent: 10,
    );
    expect(s[0].consumed, 100);
    expect(s[1].consumed, 50);
    expect(s[0].total, closeTo(110, 1e-9));
    expect(s[1].total, closeTo(55, 1e-9));
    expect(s.fold<double>(0, (a, p) => a + p.total), closeTo(165, 1e-9));
  });

  test('formato de dinero', () {
    expect(money(1234.5), '\$1,234.50');
    expect(parseNumber('1,000.5'), 1000.5);
  });
}
