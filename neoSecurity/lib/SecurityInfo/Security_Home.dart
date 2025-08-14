import 'package:flutter/material.dart';
import 'package:neosecurity/SecurityInfo/SecurityCus_Info.dart';
import 'package:neosecurity/SecurityInfo/DvrInfo.dart';
import 'package:neosecurity/SecurityInfo/Sign_Info.dart';
import 'package:neosecurity/Modal/Modal_page_List.dart';
import 'package:neosecurity/globals.dart';

import '../functions.dart';

class SecurityHome extends StatefulWidget {
  const SecurityHome({super.key});
  @override
  State<SecurityHome> createState() => SecurityHomeState();
}

class SecurityHomeState extends State<SecurityHome> {
  late int _Index = 0;
  late String title = '타이틀 없음';
  final List<Widget> _pages = [SecurityCusInfo(), SignInfo(), DvrInfo()];

  void _onItemSelected(int index, String newTitle) {
    setState(() {
      print('index$index');
      _Index = index;
      title = newTitle;
    });
    tabSecurityIndex = index;
  }

  // void _setTitle(String newTitle) {
  //   setState(() {
  //     title = newTitle;
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _Index = tabSecurityIndex;
    title = securityPageList[_Index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  backgroundColor: Colors.white,
                  builder:
                      (context) => pageList(
                        context: context,
                        itemList: securityPageList,
                        onItemSelected: _onItemSelected,
                      ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 10,
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                elevation: 0,
                shadowColor: Colors.transparent,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_more),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
      ),
      backgroundColor: const Color(0xfff7f7f7),
      body: _pages[_Index],
    );
  }
}
