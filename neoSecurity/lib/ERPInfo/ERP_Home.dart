import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neosecurity/ERPInfo/Bill_Info.dart';
import 'package:neosecurity/ERPInfo/Claim_Info.dart';
import 'package:neosecurity/ERPInfo/ERPCus_Info.dart';
import 'package:neosecurity/Modal/Modal_page_List.dart';
import 'package:neosecurity/globals.dart';

import '../RestAPI.dart';
import '../functions.dart';

class ErpHome extends StatefulWidget {
  const ErpHome({super.key});
  @override
  State<ErpHome> createState() => ErpHomeState();
}

class ErpHomeState extends State<ErpHome> {
  late int _Index = 0;
  late String title = '타이틀 없음';
  List<String> itemList = cusPageList;
  final List<Widget> _pages = [ERPCusInfo(), ClaimInfo(), BillInfo()];
  Timer? _dataCheckTimer;
  void _onItemSelected(int index, String newTitle) {
    setState(() {
      _Index = index;
      title = newTitle;
    });
    tabERPIndex = index;
  }

  // void _setTitle(String newTitle) {
  //   setState(() {
  //     title = newTitle;
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _Index = tabERPIndex;
    title = itemList[_Index];

    print('getErpCustomer 완료');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
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
                        itemList: itemList,
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
