import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/widgets/widgets.dart';

import 'feature_widgets_test.dart' show wrapWithLanguage;

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async => tester.pumpWidget(await wrapWithLanguage(SizedBox(height: 600, child: child)));

  test('statusOf: error > loading > empty > ready', () {
    expect(RiungStateView.statusOf(loading: true, error: 'x', empty: true), RiungViewStatus.error);
    expect(RiungStateView.statusOf(loading: true, empty: true), RiungViewStatus.loading);
    expect(RiungStateView.statusOf(empty: true), RiungViewStatus.empty);
    expect(RiungStateView.statusOf(), RiungViewStatus.ready);
  });

  testWidgets('RiungAsyncView: skeleton → error + coba lagi → data', (tester) async {
    var calls = 0;
    final first = Completer<List<int>>();
    await pump(
      tester,
      RiungAsyncView<List<int>>(
        load: () {
          calls++;
          return calls == 1 ? first.future : Future.value([1, 2]);
        },
        isEmpty: (d) => d.isEmpty,
        empty: const RiungEmptyState(title: 'kosong'),
        builder: (context, d) => Text('data ${d.length}'),
      ),
    );
    expect(find.byType(RiungSkeletonList), findsOneWidget);

    first.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.byType(RiungErrorWidget), findsOneWidget);

    await tester.tap(find.byType(RiungButton));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('data 2'), findsOneWidget);
  });

  testWidgets('RiungAsyncView: data kosong → empty state', (tester) async {
    await pump(
      tester,
      RiungAsyncView<List<int>>(
        load: () async => const [],
        isEmpty: (d) => d.isEmpty,
        empty: const RiungEmptyState(title: 'kosong'),
        builder: (context, d) => const Text('data'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('kosong'), findsOneWidget);
    expect(find.text('data'), findsNothing);
  });
}
