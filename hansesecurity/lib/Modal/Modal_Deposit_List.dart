import 'package:flutter/material.dart';
import 'package:hansesecurity/globals.dart' as globals;

class DepositList extends StatefulWidget {
  const DepositList({super.key});

  @override
  State<DepositList> createState() => _DepositListState();
}

class _DepositListState extends State<DepositList> {
  late int Index;
  late String title;
  void _onItemSelected(int selectInt) {
    setState(() {});
    Navigator.pop(context, selectInt);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '입금방법 선택',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 버튼 목록
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(globals.depositList.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: TextButton(
                    onPressed: () {
                      _onItemSelected(index);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 10,
                      ),
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.transparent,
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      globals.depositList[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
