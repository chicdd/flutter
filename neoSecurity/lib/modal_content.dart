// modal_content.dart
import 'package:flutter/material.dart';

Widget buildModalContent(BuildContext context) {
  return Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      top: 20,
      left: 16,
      right: 16,
    ),
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.85, // 화면 높이 95% 사용
      child: Column(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '모달 타이틀',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  hintText: '물건정보 검색',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Color(0xfff4f4f4),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12),
                    ), // 여기가 중요!
                    borderSide: BorderSide.none, // 테두리 선 없애고 배경만 살리기
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // 버튼을 가로로 꽉 채우고 싶다면 추가
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: TextButton(
                      onPressed: () {
                        // 버튼 동작
                        print('Button ${index + 1} pressed');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 10,
                        ),
                        foregroundColor: Colors.black, // 텍스트 색
                        backgroundColor: Colors.transparent, // 배경 투명
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          // side: const BorderSide(
                          //   color: Colors.black12,
                          // ), // 경계선 (선택 사항)
                        ),
                      ),
                      child: Text(
                        '버튼 ${index + 1}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    ),
  );
}
