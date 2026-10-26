import 'package:flutter_test/flutter_test.dart';
import 'package:seavis/main.dart';

void main() {
  testWidgets('SEAVIS fisherman landing page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SeavisApp());
    await tester.pumpAndSettle();

    // Pastikan Landing Page Nelayan tampil
    expect(find.text('SeaVis Nelayan'), findsOneWidget);
    expect(find.text('Saldo Siap Ditarik'), findsOneWidget);
    expect(find.text('Kirim Foto'), findsOneWidget);
    expect(find.text('Tarik Tunai'), findsWidgets);
    expect(find.text('Tanya AI'), findsOneWidget);
  });
}
