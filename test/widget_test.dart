import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ydiary/main.dart';

void main() {
  testWidgets('土地利用状況画面が表示される', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: YasaiApp()));

    expect(find.text('やさい日記'), findsOneWidget);
    expect(find.textContaining('区画1'), findsOneWidget);
    expect(find.textContaining('区画2'), findsOneWidget);
  });
}
