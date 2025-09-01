import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hansesecurity/globals.dart';

class ModalSignFilter extends StatefulWidget {
  const ModalSignFilter({super.key});

  @override
  State<ModalSignFilter> createState() => _ModalSignFilterState();
}

class _ModalSignFilterState extends State<ModalSignFilter> {
  int _periodIndex = periodIndex; // 라디오 버튼 기본 상태
  int _sortOrderIndex = sortOrderIndex; // 라디오 버튼 기본 상태
  int _classIndex = signIndex;

  DateTime startDate = day_start; // 시작 날짜
  DateTime endDate = day_end; // 종료 날짜
  void onPressed() async {
    periodIndex = _periodIndex;
    sortOrderIndex = _sortOrderIndex;
    signalClassIndex = _classIndex; //적용버튼 눌렀을때의
    signIndex = _classIndex; //신호를 고르기만했을 때에도 적용
    day_start = startDate;
    day_end = endDate;
    Navigator.pop(context, [
      periodIndex,
      sortOrderIndex,
      signalClassIndex,
      startDate,
      endDate,
    ]);
    print(signIndex);
  }

  // int _periodIndex = periodIndex; // 라디오 버튼 기본 상태
  // int _sortOrderIndex = sortOrderIndex; // 라디오 버튼 기본 상태// 라디오 버튼 기본 상태
  //
  // DateTime startDate = DateTime.now().subtract(Duration(days: 7)); // 시작 날짜
  // DateTime endDate = DateTime.now(); // 종료 날짜
  // void onPressed() async {
  //   periodIndex = _periodIndex;
  //   sortOrderIndex = _sortOrderIndex;
  //   String signalClassIndex = signList[signalClassIndex];
  //   setState(() {});
  //   Navigator.pop(context, {
  //     periodIndex,
  //     sortOrderIndex,
  //     signalClassIndex,
  //   });
  //   print(periodIndex);
  //   print(sortOrderIndex);
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

              // 조회기간 제목
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '조회기간',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ 조회기간
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Row(
                  children: [
                    viewPeriod(0),
                    const SizedBox(width: 10),
                    viewPeriod(1),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (_periodIndex == 0) // 라디오버튼 상태가 지정기간이면
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey, // 테두리 색상
                      width: 1.0, // 테두리 두께
                    ),
                    borderRadius: BorderRadius.circular(12), // 둥근 모서리 (선택)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: dateStart,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 30,
                          ),
                          child: Text(
                            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              // decoration:
                              //     TextDecoration
                              //         .underline, // 클릭 가능하단 느낌 줄 수도 있음
                              // color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      Text('-'),
                      GestureDetector(
                        onTap: dateEnd,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 30,
                          ),
                          child: Text(
                            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              // decoration:
                              //     TextDecoration
                              //         .underline, // 클릭 가능하단 느낌 줄 수도 있음
                              // color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

              //신호별 조회기능 구현 안 되어 주석처리.
              // const SizedBox(height: 30),
              //
              // // 신호구분 제목
              // const Align(
              //   alignment: Alignment.centerLeft,
              //   child: Text(
              //     '신호구분',
              //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //   ),
              // ),
              //
              // const SizedBox(height: 20),
              //
              // SizedBox(
              //   width: double.infinity,
              //   child: SignSelect(
              //     signal: "신호명",
              //     onPressed: (int selectedIndex) {
              //       setState(() {
              //         _classIndex = selectedIndex;
              //       });
              //     },
              //   ),
              // ),
              const SizedBox(height: 40),

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
}
