import 'package:flutter/material.dart';
import 'package:sheetgenerator/Modal_Select_List.dart';
import 'package:sheetgenerator/globals.dart' as globals;

class Select extends StatefulWidget {
  final String selectClass;
  final String selectDefault;
  final Function(int) onPressed;

  const Select({
    super.key,
    required this.selectClass,
    required this.selectDefault,
    required this.onPressed,
  });
  @override
  State<Select> createState() => _SelectState();
}

class _SelectState extends State<Select> {
  String selectClass = "";
  void onPressed() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => SelectList(
        selectClass: widget.selectClass,
        selectDefault: widget.selectDefault,
      ),
    );

    if (result != null && result is int) {
      setState(() {
        if (widget.selectClass == "Customer") {
          selectClass = globals.customerList[result].name;
        } else if (widget.selectClass == "Manager") {
          selectClass = globals.managerList[result].name;
        }
        widget.onPressed(result);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selectClass = widget.selectDefault;
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
              selectClass,
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

// Map<String, dynamic> SelectChanger(String customer) {
//   Map<String, dynamic> selectedModel;
//   switch (customer) {
//     case 'Customer':
//       selectedModel = CustomerModel(); // 예: Customer 모델 객체
//       break;
//     case 'Target':
//       selectedModel = ProductModel(); // 예: Product 모델 객체
//       break;
//     default:
//       selectedModel = null;
//   }
//   return selectedModel;
// }
