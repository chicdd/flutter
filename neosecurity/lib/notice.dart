import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Home.dart';
import 'RestAPI.dart';
import 'globals.dart';

class Notice extends StatefulWidget {
  const Notice({super.key});
  @override
  _NoticeState createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  Timer? _dataCheckTimer;

  Future<void> fetchNotice() async {
    try {
      final result = await noticeRequest(syscode, phoneCode);
      noticeList = result;
      //print("noticeList: ${noticeList}");
    } catch (e) {
      //print("API 호출 오류: $e");
    }
    print('api호출함');
  }

  @override
  void dispose() {
    _dataCheckTimer?.cancel();
    super.dispose();
  }

  void _startDataMonitoring() {
    int attemptCount = 0; // 시도 횟수 카운터 추가
    const int maxAttempts = 20; // 최대 시도 횟수

    _dataCheckTimer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      attemptCount++; // 시도 횟수 증가

      // cusList, stateList, state 모두 체크
      bool noticeListReady = noticeList.isNotEmpty;

      if (noticeListReady && mounted) {
        setState(() {
          // Select 위젯 업데이트를 위한 setState
        });
        // 데이터를 받았으므로 타이머 중지
        timer.cancel();
      } else if (attemptCount >= maxAttempts) {
        // 20번 시도 후에도 데이터가 없으면 타이머 중지
        timer.cancel();
        print('응답없음 - ${maxAttempts}번 시도 후 타임아웃');
        fetchNotice();
        print('최종 상태 - noticeListReady: $noticeListReady');
      } else {
        // 디버깅용 로그 (시도 횟수 포함)
        print(
          '데이터 대기 중 ($attemptCount/$maxAttempts) - noticeListReady: $noticeListReady',
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchNotice();
    _startDataMonitoring();
    // time 값의 역순으로 정렬 (최신순)
    noticeList.sort(
      (a, b) =>
          DateTime.parse(b['time']!).compareTo(DateTime.parse(a['time']!)),
    );
    print(noticeList);
  }

  String formatDate(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}..';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(
          color: Colors.black, // 색변경
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          },
        ),
        title: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(
                '공지사항',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: noticeList.length,
        itemBuilder: (context, index) {
          final notice = noticeList[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                childrenPadding: EdgeInsets.all(16.0),
                expandedAlignment: Alignment.centerLeft,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '공지',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          formatDate(notice['time']!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      truncateText(notice['body']!, 50),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              formatDate(notice['time']!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          notice['body']!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
