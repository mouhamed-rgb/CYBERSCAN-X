import 'package:flutter_test/flutter_test.dart';
import 'package:cyberscan_x/main.dart';

void main() {
  testWidgets('CYBERSCAN X dashboard renders', (tester) async {
    await tester.pumpWidget(const CyberScanApp());
    expect(find.text('CYBERSCAN X'), findsOneWidget);
    expect(find.text('مركز الأدوات'), findsOneWidget);
  });
}
