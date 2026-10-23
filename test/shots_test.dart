// Genera capturas para la ficha de Play sin emulador:
//   SHOTS=1 flutter test test/shots_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:divide_cuenta/equal_page.dart';
import 'package:divide_cuenta/items_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}

void main() {
  final enabled = Platform.environment['SHOTS'] == '1';
  testWidgets('capturas', skip: !enabled, (tester) async {
    final sdk = Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    await _font('Roboto', '$fonts/roboto-regular.ttf');
    await _font('Roboto', '$fonts/roboto-bold.ttf');
    await _font('MaterialIcons', '$fonts/materialicons-regular.otf');

    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2160);
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    Future<void> shot(Widget page, String title, int tab, String name,
        {double scroll = 0}) async {
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF059669),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: page,
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.balance), label: 'Iguales'),
                NavigationDestination(
                    icon: Icon(Icons.restaurant_menu), label: 'Por consumo'),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      if (scroll != 0) {
        await tester.drag(find.byType(ListView).first, Offset(0, -scroll));
        await tester.pumpAndSettle();
      }
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.625);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('store/$name').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    await shot(const EqualPage(), 'Partes iguales', 0, 'screenshot_1.png');
    await shot(const EqualPage(), 'Partes iguales', 0, 'screenshot_2.png',
        scroll: 700);
    await shot(const ItemsPage(), 'Por consumo', 1, 'screenshot_3.png');
    await shot(const ItemsPage(), 'Por consumo', 1, 'screenshot_4.png',
        scroll: 900);
  });
}
