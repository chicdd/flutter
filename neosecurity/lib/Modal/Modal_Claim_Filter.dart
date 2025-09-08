import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neosecurity/Select/Claim_Select.dart';
import 'package:neosecurity/Select/Deposit_Select.dart';
import 'package:neosecurity/Select/Sales_Select.dart';
import 'package:neosecurity/globals.dart';

class ModalClaimFilter extends StatefulWidget {
  const ModalClaimFilter({super.key});

  @override
  State<ModalClaimFilter> createState() => _ModalClaimFilterState();
}

class _ModalClaimFilterState extends State<ModalClaimFilter> {
  int _periodIndex = claimPeriodIndex; // 라디오 버튼 기본 상태
  int _sortOrderIndex = claimSortOrderIndex; // 라디오 버튼 기본 상태
  int _depositclassIndex = depositClassIndex;
  int _salesclassIndex = salesClassIndex;
  int _claimclassIndex = claimClassIndex;

  // List<String> periodFilter = [];
  // List<String> sortOrderFilter = [];
  // List<String> classFilter = [];

  DateTime startDate = DateTime.now().subtract(Duration(days: 7)); // 시작 날짜
  DateTime endDate = DateTime.now(); // 종료 날짜
  void onPressed() async {
    claimPeriodIndex = _periodIndex;
    claimSortOrderIndex = _sortOrderIndex;

    depositClassIndex = _depositclassIndex;
    depositIndex = _depositclassIndex;

    salesClassIndex = _salesclassIndex;
    salesIndex = _salesclassIndex;

    claimClassIndex = _claimclassIndex; //적용버튼 눌렀을때의
    claimIndex = _claimclassIndex; //신호를 고르기만했을 때에도 적용

    //print(globals.claimPeriodIndex);
    //print(globals.claimSortOrderIndex);
    //print('depositClassIndex' + globals.depositClassIndex.toString());
    //print('salesClassIndex' + globals.salesClassIndex.toString());
    //print('claimClassIndex' + globals.claimClassIndex.toString());

    setState(() {});

    Navigator.pop(context, [
      claimPeriodIndex,
      claimSortOrderIndex,
      depositClassIndex,
      salesClassIndex,
      claimClassIndex,
    ]);
  }

  // int _periodIndex = globals.periodIndex; // 라디오 버튼 기본 상태
  // int _sortOrderIndex = globals.sortOrderIndex; // 라디오 버튼 기본 상태// 라디오 버튼 기본 상태
  //
  // DateTime startDate = DateTime.now().subtract(Duration(days: 7)); // 시작 날짜
  // DateTime endDate = DateTime.now(); // 종료 날짜
  // void onPressed() async {
  //   globals.periodIndex = _periodIndex;
  //   globals.sortOrderIndex = _sortOrderIndex;
  //   String signalClassIndex = globals.signList[globals.signalClassIndex];
  //   setState(() {});
  //   Navigator.pop(context, {
  //     globals.periodIndex,
  //     globals.sortOrderIndex,
  //     signalClassIndex,
  //   });
  //   print(globals.periodIndex);
  //   print(globals.sortOrderIndex);
  //   print(signalClassIndex);
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 16,
        right: 16,
      ),
      child: Wrap(
        children: [
          Column(
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '필터',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 정렬순서 제목
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '정렬순서',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ 정렬순서
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Row(
                  children: [
                    sortOrder(0),
                    const SizedBox(width: 10),
                    sortOrder(1),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 입금방법 제목
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '입금방법',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: DepositSelect(
                  deposit: "입금방법명",
                  onPressed: (int selectedIndex) {
                    setState(() {
                      _depositclassIndex = selectedIndex;
                    });
                  },
                ),
              ),

              const SizedBox(height: 30),

              // 매출종류 제목
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '매출종류',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: SalesSelect(
                  sales: "매출종류명",
                  onPressed: (int selectedIndex) {
                    setState(() {
                      _salesclassIndex = selectedIndex;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),

              // 청구 구분 제목
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '청구 구분',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ClaimSelect(
                  claim: "청구구분명",
                  onPressed: (int selectedIndex) {
                    setState(() {
                      _claimclassIndex = selectedIndex;
                    });
                  },
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2196f3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('적용'),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ],
      ),
    );
  }

  //조회기간 라디오버튼
  Widget viewPeriod(int index) {
    final bool isSelected = _periodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _periodIndex = index; //전역변수의 상태값을 바꿔줌.
            //print("조회기간인덱스 : " + _periodIndex.toString());
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xff2196f3) : Color(0xffefefef),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            periodList[index],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  //정렬순서 라디오버튼
  Widget sortOrder(int index) {
    final bool isSelected = _sortOrderIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _sortOrderIndex = index;
            //print("정렬순서인덱스 : " + _sortOrderIndex.toString());
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xff2196f3) : Color(0xffefefef),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            sortOrderList[index],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void dateStart() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.white,
            height: 300,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: startDate,
              maximumDate: DateTime.now(),
              onDateTimeChanged: (date) {
                setState(() {
                  startDate = date;
                });
              },
            ),
          ),
        );
      },
      barrierDismissible: true,
    );
  }

  void dateEnd() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            color: Colors.white,
            height: 300,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: endDate,
              maximumDate: DateTime.now(),
              onDateTimeChanged: (date) {
                setState(() {
                  endDate = date;
                });
              },
            ),
          ),
        );
      },
      barrierDismissible: true,
    );
  }

  // //청구 구분 라디오버튼
  // Widget Claimclass(int index) {
  //   final bool isSelected = _claimclassIndex == index;
  //   return Expanded(
  //     child: GestureDetector(
  //       onTap: () {
  //         setState(() {
  //           _claimclassIndex = index; //전역변수의 상태값을 바꿔줌.
  //           print("청구종류인덱스 : " + _claimclassIndex.toString());
  //         });
  //       },
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(vertical: 20),
  //         decoration: BoxDecoration(
  //           color: isSelected ? Color(0xff2196f3) : Color(0xffefefef),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         alignment: Alignment.center,
  //         child: Text(
  //           globals.claimList[index],
  //           style: TextStyle(
  //             color: isSelected ? Colors.white : Colors.black54,
  //             fontWeight: FontWeight.w500,
  //             fontSize: 16,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
