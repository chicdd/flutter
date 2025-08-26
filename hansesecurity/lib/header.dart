import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticky Header Demo',
      home: const StickyHeaderExample(),
    );
  }
}

class StickyHeaderExample extends StatefulWidget {
  const StickyHeaderExample({super.key});
  @override
  State<StickyHeaderExample> createState() => _StickyHeaderExampleState();
}

class _StickyHeaderExampleState extends State<StickyHeaderExample> {
  // 예시 데이터: 날짜별 그룹화된 리스트
  final Map<String, List<String>> groupedItems = {
    '2025-07-15': ['아이템 1', '아이템 2', '아이템 3'],
    '2025-07-14': ['아이템 4', '아이템 5'],
    '2025-07-13': ['아이템 6', '아이템 7', '아이템 8', '아이템 9'],
  };

  @override
  Widget build(BuildContext context) {
    final dates = groupedItems.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Sticky Header 동적 리스트 예제')),
      body: CustomScrollView(
        slivers:
            dates.map((date) {
              final items = groupedItems[date]!;

              return SliverStickyHeader(
                header: Container(
                  height: 50.0,
                  color: Colors.blueGrey,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    date,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(title: Text(items[index])),
                    childCount: items.length,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
