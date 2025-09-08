import 'package:flutter/material.dart';
import 'package:neosecurity/Modal/Modal_Signal_List.dart';
import 'package:neosecurity/globals.dart';

class SignSelect extends StatefulWidget {
  final String signal;
  final Function(int) onPressed;

  const SignSelect({super.key, required this.signal, required this.onPressed});
  @override
  State<SignSelect> createState() => _SignSelectState();
}

class _SignSelectState extends State<SignSelect> {
  String signal = signList[signIndex]; //신호 드롭다운 처음 상태

  void onPressed() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => const SignalList(),
    );

    if (result != null && result is int) {
      setState(() {
        signal = signList[result];
        print(result);
        widget.onPressed(result); // 부모에 전달
        //Navigator.pop(context, result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Colors.black12, // 테두리 색상
              width: 1.0, // 테두리 두께
            ),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              signal,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}
