import 'package:flutter/material.dart';
import 'package:untitled1/Modal_Customer.dart';
import 'package:untitled1/Modal_Filter.dart';

class SignInfo extends StatefulWidget {
  const SignInfo({super.key});

  @override
  State<SignInfo> createState() => _SignInfoState();
}

class _SignInfoState extends State<SignInfo> {
  final List<Map<String, String>> signalHistory = [
    {
      "date": "2025-04-30",
      "time": "06:52:38",
      "status": "해제_[04]",
      "user": "김정석",
      "icon": "open",
    },
    {
      "date": "2025-04-30",
      "time": "06:52:33",
      "status": "경계_[04]",
      "user": "김정석",
      "icon": "lock",
    },
    {
      "date": "2025-04-30",
      "time": "06:45:43",
      "status": "원격해제요청",
      "user": "",
      "icon": "open",
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '신호 정보',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
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
                      builder: (BuildContext context) => modalCustomer(context),
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
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text("지정기간", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4), // 간격 추가
                      Text("·", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4), // 간격 추가
                      Text("최신순", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4), // 간격 추가
                      Text("·", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4), // 간격 추가
                      Text("전체", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
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
                            (BuildContext context) =>
                                const ModalFilter(), // ✅ 클래스 호출
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: Container(
                color: const Color(0xffd9d9d9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '2025.04.30',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: signalHistory.length,
                  itemBuilder: (context, index) {
                    final item = signalHistory[index];
                    final isUnlock = item['icon'] == 'open';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 30,
                      ),
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['time'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(
                                    isUnlock
                                        ? Icons.lock_open_outlined
                                        : Icons.lock_outline,
                                    size: 20,
                                    color:
                                        isUnlock
                                            ? Color(0xfff32152)
                                            : Colors.blue,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    item['status'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          isUnlock
                                              ? Color(0xfff32152)
                                              : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if ((item['user'] ?? '').isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  item['user'] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
