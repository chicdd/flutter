import 'package:flutter/material.dart';
import 'package:hansesecurity/Modal/Modal_Customer_List.dart';
import 'package:hansesecurity/functions.dart';
import 'package:hansesecurity/globals.dart';

class CusSelect extends StatefulWidget {
  final VoidCallback onPressed;
  final title;
  const CusSelect({super.key, this.title, required this.onPressed});
  @override
  State<CusSelect> createState() => _CusSelectState();
}

class _CusSelectState extends State<CusSelect> {
  String title = "";

  void onPressed() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => const CustomerList(),
    );

    if (result != null) {
      setState(() {
        title = result['name']!;
        print(result);
        //selectCusList = result;
        selectInt = cusList.indexOf(result);
        //관제고객 상태 업데이트
      });

      try {
        await getState();
        print('getState 완료');
      } catch (e) {
        print('getState 에러: $e');
      }
      widget.onPressed();
    }
  }

  @override
  void initState() {
    super.initState();

    print('title$title');
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
                  cusList.isNotEmpty
                      ? cusList[selectInt]['name'] ?? '값 없음'
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
