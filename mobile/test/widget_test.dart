import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:homeschool_keeper/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: HomeschoolKeeperApp(),
      ),
    );

    // Verify that the app builds without error
    expect(find.byType(HomeschoolKeeperApp), findsOneWidget);
  });
}
