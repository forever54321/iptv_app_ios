import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/models/epg_program.dart';
import 'package:iptv_app/models/m3u_entry.dart';
import 'package:iptv_app/providers/channel_list_provider.dart';
import 'package:iptv_app/providers/epg_provider.dart';
import 'package:iptv_app/screens/epg/epg_screen.dart';

class _FakeEpg extends EpgNotifier {
  _FakeEpg(this.data);
  final Map<String, List<EpgProgram>> data;
  @override
  Future<Map<String, List<EpgProgram>>> build() async => data;
}

void main() {
  final now = DateTime.now();
  final channels = [
    for (var i = 0; i < 40; i++)
      M3uEntry(title: 'Channel $i', url: 'http://x/$i.ts', tvgId: 'ch$i'),
  ];
  final epg = {
    for (var i = 0; i < 40; i++)
      'ch$i': [
        for (var h = -2; h < 20; h++)
          EpgProgram(
            channelId: 'ch$i',
            start: DateTime(now.year, now.month, now.day, now.hour + h),
            stop: DateTime(now.year, now.month, now.day, now.hour + h + 1),
            title: 'Show $i/$h',
          ),
      ],
  };

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        channelListProvider.overrideWith((ref) async => channels),
        epgProvider.overrideWith(() => _FakeEpg(epg)),
      ],
      child: const MaterialApp(home: EpgScreen()),
    ));
    await tester.pumpAndSettle();
  }

  List<ScrollableState> vertical(WidgetTester t) => t
      .stateList<ScrollableState>(find.byType(Scrollable))
      .where((s) => s.position.axis == Axis.vertical && s.position.maxScrollExtent > 0)
      .toList();
  ScrollableState horizontal(WidgetTester t) => t
      .stateList<ScrollableState>(find.byType(Scrollable))
      .firstWhere((s) => s.position.axis == Axis.horizontal && s.position.maxScrollExtent > 1000); // the timeline, not the search field

  testWidgets('channel column and programs scroll up/down together', (tester) async {
    await pump(tester);
    expect(vertical(tester).length, 2);
    await tester.drag(find.text('Show 5/0').first, const Offset(0, -900));
    await tester.pumpAndSettle();
    final v = vertical(tester);
    expect(v[0].position.pixels, greaterThan(100));
    expect(v[0].position.pixels, closeTo(v[1].position.pixels, 0.5));
    // and the other way: drag the channel column
    await tester.drag(find.text('Channel 12'), const Offset(0, 400));
    await tester.pumpAndSettle();
    final v2 = vertical(tester);
    expect(v2[0].position.pixels, closeTo(v2[1].position.pixels, 0.5));
  });

  testWidgets('scrolling up/down does not move the timeline sideways', (tester) async {
    await pump(tester);
    final before = horizontal(tester).position.pixels;
    expect(before, greaterThan(0), reason: 'opens at "now"');
    await tester.drag(find.text('Show 3/0').first, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(horizontal(tester).position.pixels, before);
  });

  testWidgets('nothing moves on its own', (tester) async {
    await pump(tester);
    final h = horizontal(tester).position.pixels;
    final v = vertical(tester).map((s) => s.position.pixels).toList();
    await tester.pump(const Duration(seconds: 5));
    expect(horizontal(tester).position.pixels, h);
    expect(vertical(tester).map((s) => s.position.pixels).toList(), v);
  });
}
