import 'package:flutter/material.dart';

class SignalClass extends StatefulWidget {
  const SignalClass({super.key});

  @override
  State<SignalClass> createState() => _SignalClassState();
}

class _SignalClassState extends State<SignalClass> {
  // ✅ 버튼 텍스트를 담을 리스트
  final List<String> buttonLabels = [
    '경계',
    '해제',
    '원격경계',
    '원격해제',
    '원격경계요청',
    '원격해제요청',
  ];

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
                  '조회 신호 선택',
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
              children: List.generate(buttonLabels.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: TextButton(
                    onPressed: () {
                      print('${buttonLabels[index]} pressed');
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
                      buttonLabels[index],
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
