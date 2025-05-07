import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neosecurity/Signal_Class.dart';

class ModalFilter extends StatefulWidget {
  const ModalFilter({super.key});

  @override
  State<ModalFilter> createState() => _ModalFilterState();
}

class _ModalFilterState extends State<ModalFilter> {
  String _selectedOption1 = '전체기간'; // 라디오 버튼 선택 상태
  String _selectedOption2 = '최신순'; // 라디오 버튼 선택 상태
  DateTime firstDay = DateTime.now(); // 초기 날짜
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
                    viewPeriod('전체기간'),
                    const SizedBox(width: 10),
                    viewPeriod('지정기간'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (_selectedOption1 == '지정기간') // 조건부 표시
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
                        onTap: _showCupertinoDatePicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 30,
                          ),
                          child: Text(
                            '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}',
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
                        onTap: _showCupertinoDatePicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 30,
                          ),
                          child: Text(
                            '${firstDay.year}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.day.toString().padLeft(2, '0')}',
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
                    sortOrder('최신순'),
                    const SizedBox(width: 10),
                    sortOrder('과거순'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 신호구분 제목
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '신호구분',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),

                    backgroundColor: const Color(0xfffafafa),
                    // 배경색
                    foregroundColor: Colors.black,
                    // 텍스트 색상
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: const Color(0xffdfdfdf), // 테두리 색상
                        width: 1, // 테두리 두께
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    // 그림자 제거
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      builder: (BuildContext context) => const SignalClass(),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("원격경계", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.expand_more),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
  Widget viewPeriod(String value) {
    final bool isSelected = _selectedOption1 == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOption1 = value;
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
            value,
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
  Widget sortOrder(String value) {
    final bool isSelected = _selectedOption2 == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOption2 = value;
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
            value,
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

  void _showCupertinoDatePicker() {
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
              initialDateTime: firstDay,
              maximumDate: DateTime.now(),
              onDateTimeChanged: (date) {
                setState(() {
                  firstDay = date;
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
