import 'package:flutter/material.dart';
import 'package:hansesecurity/Modal/Modal_Bill_List.dart';
import 'package:hansesecurity/globals.dart';

//계산서내역 필터의 모달 내 계산서종류 셀렉트
class BillSelect extends StatefulWidget {
  final String bill;
  final Function(int) onPressed;

  const BillSelect({super.key, required this.bill, required this.onPressed});
  @override
  State<BillSelect> createState() => _BillSelectState();
}

class _BillSelectState extends State<BillSelect> {
  String bill = billClassList[billIndex]; //신호 드롭다운 처음 상태

  void onPressed() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => const BillList(),
    );

    if (result != null && result is int) {
      setState(() {
        bill = billClassList[result];
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
              bill,
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
