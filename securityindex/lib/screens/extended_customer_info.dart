import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/customer.dart';
import '../models/customer_detail.dart';
import '../services/database_service.dart';
import '../widgets/time_picker_modal.dart';
import '../style.dart';
import '../widgets/custom_top_bar.dart';
import '../config/topbar_config.dart';

class ExtendedCustomerInfo extends StatefulWidget {
  final Customer? customer;

  const ExtendedCustomerInfo({Key? key, this.customer}) : super(key: key);

  @override
  State<ExtendedCustomerInfo> createState() => _ExtendedCustomerInfoState();
}

class _ExtendedCustomerInfoState extends State<ExtendedCustomerInfo> {
  // 경계약정 및 무단해제 설정 - 평일
  int _weekdayGuardStartHour = 0;
  int _weekdayGuardStartMinute = 30;
  int _weekdayGuardEndHour = 9;
  int _weekdayGuardEndMinute = 0;
  int _weekdayUnauthorizedStartHour = 9;
  int _weekdayUnauthorizedStartMinute = 0;
  int _weekdayUnauthorizedEndHour = 9;
  int _weekdayUnauthorizedEndMinute = 0;
  bool _isWeekdayUsed = true;

  // 경계약정 및 무단해제 설정 - 주말
  int _weekendGuardStartHour = 0;
  int _weekendGuardStartMinute = 30;
  int _weekendGuardEndHour = 9;
  int _weekendGuardEndMinute = 0;
  int _weekendUnauthorizedStartHour = 9;
  int _weekendUnauthorizedStartMinute = 0;
  int _weekendUnauthorizedEndHour = 9;
  int _weekendUnauthorizedEndMinute = 0;
  bool _isWeekendUsed = true;

  // 경계약정 및 무단해제 설정 - 휴일
  int _holidayGuardStartHour = 0;
  int _holidayGuardStartMinute = 30;
  int _holidayGuardEndHour = 9;
  int _holidayGuardEndMinute = 0;
  int _holidayUnauthorizedStartHour = 9;
  int _holidayUnauthorizedStartMinute = 0;
  int _holidayUnauthorizedEndHour = 9;
  int _holidayUnauthorizedEndMinute = 0;
  bool _isHolidayUsed = true;

  // 주간 휴일설정 - 5주 x 7일
  final List<List<bool>> _weeklyHolidays = List.generate(
    5,
    (_) => List.generate(7, (_) => false),
  );

  // 내보내기 드롭다운
  bool _isExportDropdownOpen = false;

  // 검색 관련
  final _searchController = TextEditingController();

  // 고객 추가 메모사항 텍스트 컨트롤러
  final _openingPhoneController = TextEditingController();
  final _openingDateController = TextEditingController();
  final _modemSerialController = TextEditingController();
  final _additionalMemoController = TextEditingController();
  final _xCoordinateController = TextEditingController();
  final _yCoordinateController = TextEditingController();
  final _companyTypeController = TextEditingController();
  final _branchTypeController = TextEditingController();
  final _dedicatedLineController = TextEditingController();
  final _dedicatedLineMemoController = TextEditingController();

  @override
  void dispose() {
    _openingPhoneController.dispose();
    _openingDateController.dispose();
    _modemSerialController.dispose();
    _additionalMemoController.dispose();
    _xCoordinateController.dispose();
    _yCoordinateController.dispose();
    _companyTypeController.dispose();
    _branchTypeController.dispose();
    _dedicatedLineController.dispose();
    _dedicatedLineMemoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 다른 곳 클릭 시 드롭다운 닫기
        if (_isExportDropdownOpen) {
          setState(() {
            _isExportDropdownOpen = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // 최소 너비 설정 (각 섹션당 최소 600px)
            final isWideScreen = constraints.maxWidth >= 1200;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isWideScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSecuritySettingsSection(), //경계약정 및 무단해제 설정
                              const SizedBox(height: 24),
                              _buildWeeklyHolidaySettings(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // 우측: 관제 기본 정보
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAdditionalInfoSection(),
                              const SizedBox(height: 24),
                              _buildServiceSection(),
                              const SizedBox(height: 24),
                              _buildDVRSection(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAdditionalInfoSection(),
                        const SizedBox(height: 24),
                        _buildServiceSection(),
                        const SizedBox(height: 24),
                        _buildDVRSection(),
                      ],
                    ),
            );
          },
        ),
        // body: SingleChildScrollView(
        //   padding: const EdgeInsets.all(24),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       _buildSecuritySettingsSection(),
        //       const SizedBox(height: 32),
        //       _buildAdditionalInfoSection(),
        //       const SizedBox(height: 32),
        //       _buildServiceSection(),
        //       const SizedBox(height: 32),
        //       _buildDVRSection(),
        //     ],
        //   ),
        // ),
      ),
    );
  }

  Widget buildExportDropdown() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExportDropdownOpen = !_isExportDropdownOpen;
            });
          },
          child: Container(
            width: 114,
            height: 35,
            decoration: ShapeDecoration(
              color: const Color(0xFFD8A68A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '내보내기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExportDropdownOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        if (_isExportDropdownOpen)
          Positioned(
            top: 45,
            left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDropdownItem('철거요청서 출력'),
                  _buildDropdownItem('고객정보시트 출력'),
                  _buildDropdownItem('감지기/존내역 출력'),
                  _buildDropdownItem('무선 정보 엑셀 저장'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownItem(String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _isExportDropdownOpen = false;
        });
        // TODO: 각 항목별 동작 구현
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF252525),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget buildTopButton(String label, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: 버튼 동작 구현
      },
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySettingsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 경계약정 및 무단해제 설정
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSectionTitle('경계약정 및 무단해제 설정'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTimeSettingCard('평일', true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimeSettingCard('주말', false)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimeSettingCard('휴일', null)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 주간 휴일설정
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: _buildWeeklyHolidaySettings(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSettingCard(String title, bool? isWeekday) {
    int guardStartHour, guardStartMinute, guardEndHour, guardEndMinute;
    int unauthStartHour, unauthStartMinute, unauthEndHour, unauthEndMinute;
    bool isUsed;

    if (isWeekday == true) {
      guardStartHour = _weekdayGuardStartHour;
      guardStartMinute = _weekdayGuardStartMinute;
      guardEndHour = _weekdayGuardEndHour;
      guardEndMinute = _weekdayGuardEndMinute;
      unauthStartHour = _weekdayUnauthorizedStartHour;
      unauthStartMinute = _weekdayUnauthorizedStartMinute;
      unauthEndHour = _weekdayUnauthorizedEndHour;
      unauthEndMinute = _weekdayUnauthorizedEndMinute;
      isUsed = _isWeekdayUsed;
    } else if (isWeekday == false) {
      guardStartHour = _weekendGuardStartHour;
      guardStartMinute = _weekendGuardStartMinute;
      guardEndHour = _weekendGuardEndHour;
      guardEndMinute = _weekendGuardEndMinute;
      unauthStartHour = _weekendUnauthorizedStartHour;
      unauthStartMinute = _weekendUnauthorizedStartMinute;
      unauthEndHour = _weekendUnauthorizedEndHour;
      unauthEndMinute = _weekendUnauthorizedEndMinute;
      isUsed = _isWeekendUsed;
    } else {
      guardStartHour = _holidayGuardStartHour;
      guardStartMinute = _holidayGuardStartMinute;
      guardEndHour = _holidayGuardEndHour;
      guardEndMinute = _holidayGuardEndMinute;
      unauthStartHour = _holidayUnauthorizedStartHour;
      unauthStartMinute = _holidayUnauthorizedStartMinute;
      unauthEndHour = _holidayUnauthorizedEndHour;
      unauthEndMinute = _holidayUnauthorizedEndMinute;
      isUsed = _isHolidayUsed;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF252525),
                    fontSize: 17,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE5E5E5)),
                const SizedBox(height: 8),
                TimePickerButton(
                  label: '경계',
                  hour: guardStartHour,
                  minute: guardStartMinute,
                  onTimeChanged: (hour, minute) {
                    setState(() {
                      if (isWeekday == true) {
                        _weekdayGuardStartHour = hour;
                        _weekdayGuardStartMinute = minute;
                      } else if (isWeekday == false) {
                        _weekendGuardStartHour = hour;
                        _weekendGuardStartMinute = minute;
                      } else {
                        _holidayGuardStartHour = hour;
                        _holidayGuardStartMinute = minute;
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE5E5E5)),
                const SizedBox(height: 8),
                TimePickerButton(
                  label: '해제',
                  hour: guardEndHour,
                  minute: guardEndMinute,
                  onTimeChanged: (hour, minute) {
                    setState(() {
                      if (isWeekday == true) {
                        _weekdayGuardEndHour = hour;
                        _weekdayGuardEndMinute = minute;
                      } else if (isWeekday == false) {
                        _weekendGuardEndHour = hour;
                        _weekendGuardEndMinute = minute;
                      } else {
                        _holidayGuardEndHour = hour;
                        _holidayGuardEndMinute = minute;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      '무단',
                      style: TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Checkbox(
                      value: isUsed,
                      onChanged: (value) {
                        setState(() {
                          if (isWeekday == true) {
                            _isWeekdayUsed = value ?? false;
                          } else if (isWeekday == false) {
                            _isWeekendUsed = value ?? false;
                          } else {
                            _isHolidayUsed = value ?? false;
                          }
                        });
                      },
                      activeColor: AppTheme.selectedColor,
                    ),
                    const Text(
                      '사용',
                      style: TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE5E5E5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '경계',
                      style: TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => TimePickerModal(
                            initialHour: unauthStartHour,
                            initialMinute: unauthStartMinute,
                            onTimeSelected: (hour, minute) {
                              setState(() {
                                if (isWeekday == true) {
                                  _weekdayUnauthorizedStartHour = hour;
                                  _weekdayUnauthorizedStartMinute = minute;
                                } else if (isWeekday == false) {
                                  _weekendUnauthorizedStartHour = hour;
                                  _weekendUnauthorizedStartMinute = minute;
                                } else {
                                  _holidayUnauthorizedStartHour = hour;
                                  _holidayUnauthorizedStartMinute = minute;
                                }
                              });
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Text(
                          '${unauthStartHour.toString().padLeft(2, '0')}시',
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => TimePickerModal(
                            initialHour: unauthStartHour,
                            initialMinute: unauthStartMinute,
                            onTimeSelected: (hour, minute) {
                              setState(() {
                                if (isWeekday == true) {
                                  _weekdayUnauthorizedStartHour = hour;
                                  _weekdayUnauthorizedStartMinute = minute;
                                } else if (isWeekday == false) {
                                  _weekendUnauthorizedStartHour = hour;
                                  _weekendUnauthorizedStartMinute = minute;
                                } else {
                                  _holidayUnauthorizedStartHour = hour;
                                  _holidayUnauthorizedStartMinute = minute;
                                }
                              });
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Text(
                          '${unauthStartMinute.toString().padLeft(2, '0')}분',
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Color(0xFFE5E5E5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '해제',
                      style: TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => TimePickerModal(
                            initialHour: unauthEndHour,
                            initialMinute: unauthEndMinute,
                            onTimeSelected: (hour, minute) {
                              setState(() {
                                if (isWeekday == true) {
                                  _weekdayUnauthorizedEndHour = hour;
                                  _weekdayUnauthorizedEndMinute = minute;
                                } else if (isWeekday == false) {
                                  _weekendUnauthorizedEndHour = hour;
                                  _weekendUnauthorizedEndMinute = minute;
                                } else {
                                  _holidayUnauthorizedEndHour = hour;
                                  _holidayUnauthorizedEndMinute = minute;
                                }
                              });
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Text(
                          '${unauthEndHour.toString().padLeft(2, '0')}시',
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => TimePickerModal(
                            initialHour: unauthEndHour,
                            initialMinute: unauthEndMinute,
                            onTimeSelected: (hour, minute) {
                              setState(() {
                                if (isWeekday == true) {
                                  _weekdayUnauthorizedEndHour = hour;
                                  _weekdayUnauthorizedEndMinute = minute;
                                } else if (isWeekday == false) {
                                  _weekendUnauthorizedEndHour = hour;
                                  _weekendUnauthorizedEndMinute = minute;
                                } else {
                                  _holidayUnauthorizedEndHour = hour;
                                  _holidayUnauthorizedEndMinute = minute;
                                }
                              });
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                        ),
                        child: Text(
                          '${unauthEndMinute.toString().padLeft(2, '0')}분',
                          style: const TextStyle(
                            color: Color(0xFF252525),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHolidaySettings() {
    final days = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionTitle('주간 휴일설정'),
        const SizedBox(height: 12),
        // 요일 헤더
        Row(
          children: [
            const SizedBox(width: 29), // 주차 번호 공간
            ...days.asMap().entries.map((entry) {
              return SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 4),
        // 5주 체크박스 그리드
        ...List.generate(5, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 25),
            child: Row(
              children: [
                // 주차 번호
                Container(
                  width: 25,
                  height: 22,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: OvalBorder(),
                  ),
                  child: Center(
                    child: Text(
                      '${weekIndex + 1}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // 7일 체크박스
                ...List.generate(7, (dayIndex) {
                  Color bgColor = Colors.white;
                  Color checkColor = Colors.black;
                  if (dayIndex == 0) {
                    // 일요일
                    bgColor = const Color(0xFFFF7070);
                    checkColor = Colors.white;
                  } else if (dayIndex == 6) {
                    // 토요일
                    bgColor = const Color(0xFF87C5FF);
                    checkColor = Colors.white;
                  }

                  return SizedBox(
                    width: 40,
                    child: Center(
                      child: Transform.scale(
                        scale: 0.85,
                        child: Theme(
                          data: ThemeData(
                            checkboxTheme: CheckboxThemeData(
                              side: const BorderSide(
                                color: Color(0xFFA8A8A8),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          child: Checkbox(
                            value: _weeklyHolidays[weekIndex][dayIndex],
                            onChanged: (value) {
                              setState(() {
                                _weeklyHolidays[weekIndex][dayIndex] =
                                    value ?? false;
                              });
                            },
                            activeColor: bgColor,
                            checkColor: checkColor,
                            side: const BorderSide(
                              color: Color(0xFFA8A8A8),
                              width: 1.5,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle('고객 추가 메모사항'),
                    const SizedBox(height: 16),
                    CommonTextField(
                      label: '개통일자',
                      controller: _openingDateController,
                    ),
                    const SizedBox(height: 12),
                    CommonTextField(
                      label: '모뎀일련번호',
                      controller: _modemSerialController,
                    ),
                    const SizedBox(height: 12),
                    CommonTextField(
                      label: '추가메모',
                      controller: _additionalMemoController,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle('고객 GPS 좌표'),
                    const SizedBox(height: 16),
                    InlineTextField(
                      label: 'X 좌표',
                      controller: _xCoordinateController,
                    ),
                    const SizedBox(height: 12),
                    InlineTextField(
                      label: 'Y 좌표',
                      controller: _yCoordinateController,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle('회사 / 지사 구분'),
                    const SizedBox(height: 16),
                    InlineTextField(
                      label: '회사구분',
                      controller: _companyTypeController,
                    ),
                    const SizedBox(height: 12),
                    InlineTextField(
                      label: '지사구분',
                      controller: _branchTypeController,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle('전용회선 관리'),
                    const SizedBox(height: 16),
                    InlineTextField(
                      label: '전용회선 번호',
                      controller: _dedicatedLineController,
                      hintText: '_ _ _ _ - _ _ _ _ - _ _ _ _',
                    ),
                    const SizedBox(height: 12),
                    InlineTextField(
                      label: '추가메모',
                      controller: _dedicatedLineMemoController,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '부가서비스 제공',
            style: TextStyle(
              color: Color(0xFF252525),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '서비스명',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '제공구분',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '제공일자',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '메모',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 테이블 내용 (샘플 데이터 3개)
          ...List.generate(3, (index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: index % 2 == 0
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFFFFFFFF),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '출입통제',
                      style: const TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '임대',
                      style: const TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '2015-09-21',
                      style: const TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '메모메모메모메모메모메모',
                      style: const TextStyle(
                        color: Color(0xFF252525),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDVRSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DVR설치현황',
            style: TextStyle(
              color: Color(0xFF252525),
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: const [
                Expanded(child: Text('접속방식', textAlign: TextAlign.center)),
                Expanded(child: Text('DVR종류코드', textAlign: TextAlign.center)),
                Expanded(child: Text('종류', textAlign: TextAlign.center)),
                Expanded(child: Text('접속주소', textAlign: TextAlign.center)),
                Expanded(child: Text('접속포트', textAlign: TextAlign.center)),
                Expanded(child: Text('접속ID', textAlign: TextAlign.center)),
                Expanded(child: Text('접속암호', textAlign: TextAlign.center)),
                Expanded(child: Text('추가일자', textAlign: TextAlign.center)),
              ],
            ),
          ),
          // 테이블 내용 (샘플 데이터)
          ...List.generate(2, (index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: index % 2 == 0
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFFFFFFFF),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
                ),
              ),
              child: Row(
                children: const [
                  Expanded(child: Text('웹', textAlign: TextAlign.center)),
                  Expanded(child: Text('DVR01', textAlign: TextAlign.center)),
                  Expanded(child: Text('하이크비전', textAlign: TextAlign.center)),
                  Expanded(
                    child: Text('192.168.0.1', textAlign: TextAlign.center),
                  ),
                  Expanded(child: Text('8000', textAlign: TextAlign.center)),
                  Expanded(child: Text('admin', textAlign: TextAlign.center)),
                  Expanded(child: Text('****', textAlign: TextAlign.center)),
                  Expanded(
                    child: Text('2023-01-15', textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
