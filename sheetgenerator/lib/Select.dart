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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.outline, // ← 카드/버튼 배경

          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectClass,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.primary,
            ),
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
