import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/widgets/riung_tab_host.dart';

void main() {
  testWidgets('tabs load on demand, retain input and mute hidden tickers', (
    tester,
  ) async {
    var index = 0;
    late StateSetter change;
    final created = <int>[];
    final children = List.generate(3, (i) => _Probe(id: i, created: created));
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            change = setState;
            return RiungTabHost(index: index, children: children);
          },
        ),
      ),
    );
    expect(created, [0]);
    await tester.enterText(find.byType(TextField), 'tersimpan');
    change(() => index = 1);
    await tester.pumpAndSettle();
    expect(created, [0, 1]);
    final hidden = tester.element(
      find.byKey(const ValueKey('input-0'), skipOffstage: false),
    );
    expect(TickerMode.valuesOf(hidden).enabled, isFalse);
    change(() => index = 0);
    await tester.pumpAndSettle();
    expect(find.text('tersimpan'), findsOneWidget);
    expect(created, [0, 1]);
    expect(
      TickerMode.valuesOf(tester.element(find.byType(TextField))).enabled,
      isTrue,
    );
  });

  testWidgets('reduced motion switches immediately, including rapid switches', (
    tester,
  ) async {
    var index = 0;
    late StateSetter change;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return RiungTabHost(
                index: index,
                children: const [Text('one'), Text('two'), Text('three')],
              );
            },
          ),
        ),
      ),
    );
    for (final i in [1, 2, 0, 2]) {
      change(() => index = i);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    }
    expect(find.text('three'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Probe extends StatefulWidget {
  const _Probe({required this.id, required this.created});
  final int id;
  final List<int> created;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.created.add(widget.id);
  }

  @override
  Widget build(BuildContext context) =>
      Material(child: TextField(key: ValueKey('input-${widget.id}')));
}
