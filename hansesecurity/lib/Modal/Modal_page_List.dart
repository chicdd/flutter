import 'package:flutter/material.dart';

Widget pageList({
  required BuildContext context,
  required List<String> itemList,
  required void Function(int, String) onItemSelected,
}) {
  return Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      top: 20,
      left: 16,
      right: 16,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            itemList.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onItemSelected(index, item);
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
                  child: Text(item, style: const TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
      ),
    ),
  );
}
