import 'package:flutter/material.dart';
import 'package:hansesecurity/Modal/Modal_ERP_List.dart';
import 'package:hansesecurity/globals.dart';

class ERPSelect extends StatefulWidget {
  final VoidCallback onPressed;
  final title;
  const ERPSelect({super.key, this.title, required this.onPressed});
  @override
  State<ERPSelect> createState() => _ERPSelectState();
}

class _ERPSelectState extends State<ERPSelect> {
  String title = "";

  void onPressed() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => const ERPList(),
    );

    if (result != null) {
      setState(() {
        title = result['name']!;
        print(result);
        //selectErpList = result;
        erpselectInt = erpList.indexOf(result);
        print(erpselectInt);
        //영업고객 상태 업데이트
      });
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title =
                  erpList.isNotEmpty
                      ? erpList[erpselectInt]['name'] ?? '값 없음'
                      : '값 없음',
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
