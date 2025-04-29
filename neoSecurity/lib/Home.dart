import 'package:flutter/material.dart';
import 'package:untitled1/modal_content.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(useMaterial3: false),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _homeState();
}

class _homeState extends State<Home> {
  // String selectedValue = '옵션 1';
  // final List<String> options = ['옵션 1', '옵션 2', '옵션 3'];

  int _selectedIndex = 2;
  String _selectedOption = '경계'; // 기본 선택값

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // 여기에 네비게이션 처리나 화면 전환 로직을 넣을 수 있어요
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefefef),
      appBar: AppBar(
        title: const Text(
          '시큐리티 정보',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xffefefef),
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),

                    backgroundColor: const Color(0xfff4f4f4), // 배경색
                    foregroundColor: Colors.black, // 텍스트 색상
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0, // 그림자 제거
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
                      builder:
                          (BuildContext context) => buildModalContent(context),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("거래처명", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.expand_more),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(15), // 원하는 radius 값
                child: Image.asset("image/경계3.jpg"),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0),
                child: Row(
                  children: [
                    _buildExpandedSelectableBox('경계'),
                    const SizedBox(width: 10),
                    _buildExpandedSelectableBox('해제'),
                  ],
                ),
              ),

              const SizedBox(height: 10),

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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('원격요청'),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 명시적으로 고정형 지정
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Color(0xffffffff), // 배경색 회색으로 맞춤
        selectedItemColor: Colors.black, // 선택된 아이템 색
        unselectedItemColor: Colors.black54, // 비선택 아이템 색
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0), // 높이를 조절하는 패딩
              child: Icon(Icons.home_filled),
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.person),
            ),
            label: '고객정보',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.list_alt),
            ),
            label: '신호정보',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.settings),
            ),
            label: '설정',
          ),
        ],
      ),
    );
  }

  //라디오버튼
  Widget _buildExpandedSelectableBox(String value) {
    final bool isSelected = _selectedOption == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOption = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
}
