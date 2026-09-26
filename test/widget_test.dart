import 'package:flutter_test/flutter_test.dart';
import 'package:libary_management/main.dart';

void main() {
  testWidgets('Hiển thị màn hình bắt đầu', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('READILY'), findsOneWidget);
    expect(find.text('Tiếp theo'), findsOneWidget);
  });
}
