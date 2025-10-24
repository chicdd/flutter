import 'package:flutter/material.dart';

class CustomerLedgerScreen extends StatefulWidget {
  const CustomerLedgerScreen({super.key});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  String _searchType = '검색 조건';
  bool _isActive = true;
  bool _isInactive = true;
  bool _isPending = true;
  bool _isTemporary = true;
  int _selectedTab = 0;

  final List<Map<String, String>> _customers = [
    {
      'number': '200500001',
      'name': '서원숙',
      'status': '정상',
      'phone': '010-1234-5678',
    },
    {
      'number': '200500002',
      'name': '(주)스마트시스',
      'status': '정상',
      'phone': '010-2345-6789',
    },
    {
      'number': '200500003',
      'name': '김민철',
      'status': '정지',
      'phone': '010-3456-7890',
    },
    {
      'number': '200500004',
      'name': '(주)신안전시스템',
      'status': '정상',
      'phone': '010-4567-8901',
    },
    {
      'number': '200500005',
      'name': 'LG전자',
      'status': '정상',
      'phone': '010-5678-9012',
    },
  ];

  int _selectedCustomerIndex = -1;

  // 고객 정보 컨트롤러들
  final _customerNumberController = TextEditingController(text: '200500002');
  final _customerNameController = TextEditingController(text: '순원 에이비씨');
  final _representativeController = TextEditingController(text: '서윤수');
  final _businessNumberController = TextEditingController(text: '123-45-67890');
  final _addressController = TextEditingController(text: '경기 수원시 권선구 권선동');
  final _detailAddressController = TextEditingController(
    text: '1296-7 베스토아빌딩7층',
  );
  final _phoneController = TextEditingController(text: '031-235-1100');
  final _mobileController = TextEditingController(text: '010-1234-5678');
  final _emailController = TextEditingController(text: 'abc@nate.com');

  @override
  void dispose() {
    _customerNumberController.dispose();
    _customerNameController.dispose();
    _representativeController.dispose();
    _businessNumberController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1200;
        final isVeryNarrow = constraints.maxWidth < 800;

        return Container(
          color: const Color(0xFFF5F5F7),
          child: Row(
            children: [
              // 좌측 검색 및 리스트 (좁은 화면에서는 숨김)
              if (!isVeryNarrow) _buildLeftSidebar(),
              // 우측 상세 정보
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isVeryNarrow ? 12 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTabSection(),
                      const SizedBox(height: 20),
                      _buildCustomerInfoSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildBusinessInfoSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildAddressInfoSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildControlInfoSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildInvoiceInfoSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildPaymentInfoSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildContractInfoSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildMonthlyFeeSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildOtherItemsSection(isNarrow, isVeryNarrow),
                      const SizedBox(height: 20),
                      _buildCustomerMemoSection(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildSearchSection(),
          Expanded(child: _buildCustomerList()),
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '고객 검색',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _searchType,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF007AFF),
                  width: 2,
                ),
              ),
            ),
            items: const [
              DropdownMenuItem(value: '검색 조건', child: Text('검색 조건')),
              DropdownMenuItem(value: '고객번호', child: Text('고객번호')),
              DropdownMenuItem(value: '고객명', child: Text('고객명')),
              DropdownMenuItem(value: '전화번호', child: Text('전화번호')),
            ],
            onChanged: (value) {
              setState(() {
                _searchType = value!;
              });
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF007AFF),
                  width: 2,
                ),
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: Color(0xFF86868B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '상태 필터',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildStatusCheckbox(
                '정상',
                _isActive,
                (val) => setState(() => _isActive = val!),
              ),
              _buildStatusCheckbox(
                '해지',
                _isInactive,
                (val) => setState(() => _isInactive = val!),
              ),
              _buildStatusCheckbox(
                '사용정지',
                _isPending,
                (val) => setState(() => _isPending = val!),
              ),
              _buildStatusCheckbox(
                '일시정지',
                _isTemporary,
                (val) => setState(() => _isTemporary = val!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCheckbox(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF007AFF) : Colors.white,
              border: Border.all(
                color: value ? const Color(0xFF007AFF) : Colors.grey.shade400,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: value
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1D1D1F)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return ListView.builder(
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];
        final isSelected = _selectedCustomerIndex == index;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedCustomerIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer['number']!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: customer['status'] == '정상'
                            ? const Color(0xFFD4EDDA)
                            : const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        customer['status']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: customer['status'] == '정상'
                              ? const Color(0xFF155724)
                              : const Color(0xFF856404),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  customer['name']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('총 고객', '450,000'),
          const SizedBox(height: 8),
          _buildSummaryRow('정구금액', '450,000'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF86868B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    final tabs = ['고객기본정보', '추가정보1', '재전송트리거', '문서', '보상금'];
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF007AFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF86868B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerInfoSection(bool isNarrow, bool isVeryNarrow) {
    // Wrap을 사용하여 화면 크기에 따라 자동으로 줄바꿈
    return _buildSection('고객정보', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildInputField('고객번호', _customerNumberController, width: 100),
          _buildInputField('상호명', _customerNameController, width: 250),
          _buildLabelField('고객상태', '정상', width: 150),
          _buildInputField('대표자', _representativeController, width: 150),
          _buildInputField('휴대전화', _mobileController, width: 150),
          _buildInputField('상호전화', _phoneController, width: 150),
          _buildInputField('팩스번호', TextEditingController(), width: 150),
        ],
      ),
    ]);
  }

  Widget _buildBusinessInfoSection(bool isNarrow, bool isVeryNarrow) {
    return _buildSection('사업자정보', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildClickInputField(
            '개인/사업자구분',
            TextEditingController(),
            width: 150,
          ),
          _buildInputField('대표자성명', TextEditingController(), width: 150),
          _buildInputField('주민등록번호', TextEditingController(), width: 150),
          _buildInputField('사업자등록상호', TextEditingController(), width: 150),
          _buildInputField('사업자등록번호', TextEditingController(), width: 120),
          _buildClickInputField('업종분류코드', TextEditingController(), width: 150),
          _buildInputField('업태', TextEditingController(), width: 150),
          _buildInputField('종목', TextEditingController(), width: 150),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildClickInputField(
                '사업자주소',
                TextEditingController(),
                width: 300,
              ),
              _buildInputField('', TextEditingController(), width: 300),
              _buildInputField('우편번호', TextEditingController(), width: 80),
            ],
          ),
        ],
      ),
    ]);
  }

  // 주소정보
  Widget _buildAddressInfoSection(bool isNarrow, bool isVeryNarrow) {
    return _buildSection('주소정보', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildClickInputField('우편물주소', TextEditingController(), width: 300),
          _buildInputField('', TextEditingController(), width: 300),
          _buildInputField('우편번호', TextEditingController(), width: 80),
        ],
      ),

      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildClickInputField('사업장주소', TextEditingController(), width: 300),
          _buildInputField('', TextEditingController(), width: 300),
          _buildInputField('우편번호', TextEditingController(), width: 80),
        ],
      ),

      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildClickInputField('자택주소', TextEditingController(), width: 300),
          _buildInputField('', TextEditingController(), width: 300),
          _buildInputField('우편번호', TextEditingController(), width: 80),
        ],
      ),
    ]);
  }

  // 관제정보
  Widget _buildControlInfoSection(bool isNarrow, bool isVeryNarrow) {
    return _buildSection('관제정보', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildInputField('관제번호', TextEditingController(), width: 100),
          _buildLabelField('단말기명', 'DCM-100', width: 150),
          _buildClickInputField('회선구분', TextEditingController(), width: 150),
          _buildInputField('KEYMAN', TextEditingController(), width: 100),
          _buildInputField('KEYMAN연락처', TextEditingController(), width: 100),
        ],
      ),
    ]);
  }

  // 계산서정보
  Widget _buildInvoiceInfoSection(bool isNarrow, bool isVeryNarrow) {
    return _buildSection('계산서정보', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildClickInputField('계산서종류', TextEditingController(), width: 150),
          _buildComboboxField(
            '계산서생성시점',
            ['매출생성시', '수금완료시'],
            '매출생성시',
            width: 150,
          ),
          _buildInputWithSuffixField(
            '계산서발행일자',
            TextEditingController(),
            '일',
            width: 90,
          ),
          _buildInputField('담당자', TextEditingController(), width: 100),
          _buildInputField('휴대전화', TextEditingController(), width: 150),
          _buildLabelField('계좌등록상태', '등록완료', width: 150),
          _buildButtonField('CMS상태변경', () {}, width: 120),
          _buildEmailField(width: 485),
          _buildInputField('계산서비고', TextEditingController(), width: 400),
        ],
      ),
    ]);
  }

  // 결제정보
  Widget _buildPaymentInfoSection(bool isNarrow, bool isVeryNarrow) {
    return _buildSection('결제정보', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildLabelField('납입방법', 'CMS', width: 150),
          _buildClickInputField('납입분류', TextEditingController(), width: 150),
          _buildInputField('지로납입기한', TextEditingController(), width: 90),
          _buildClickInputField('은행명', TextEditingController(), width: 150),
          _buildInputField('은행계좌번호', TextEditingController(), width: 200),
          _buildInputField('이체일자', TextEditingController(), width: 150),
          _buildComboboxField('방문수금', ['방문1', '방문2', '방문3'], '방문1', width: 150),
          _buildInputField('예금주', TextEditingController(), width: 150),
          _buildInputField('예금주관계', TextEditingController(), width: 150),
          _buildInputField('생년월일/사업자번호', _businessNumberController, width: 200),
          _buildInputField('납부자번호', TextEditingController(), width: 150),
          _buildClickInputField('청구서발송여부', TextEditingController(), width: 150),
          _buildClickInputField('과금중지설정', TextEditingController(), width: 150),
          _buildDateField('재과금', TextEditingController(), width: 150),
          _buildCheckboxField('CMS할인', false, (val) {}, width: 150),
        ],
      ),
    ]);
  }

  // 계약정보
  Widget _buildContractInfoSection(bool isNarrow, bool isVeryNarrow) {
    return _buildSection('계약정보', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildClickInputField('계약구분', TextEditingController(), width: 150),
          _buildClickInputField('계약전환구분', TextEditingController(), width: 150),
          _buildClickInputField('계약종류', TextEditingController(), width: 150),
          _buildDateField('계약일자', TextEditingController(), width: 150),
          _buildDateField('경비개시일', TextEditingController(), width: 150),
          _buildDateField('계약만료일', TextEditingController(), width: 150),

          Wrap(
            children: [
              _buildInputWithSuffixField(
                '계약기간',
                TextEditingController(),
                '개월',
                width: 70,
              ),
              SizedBox(width: 10),
              _buildInputWithSuffixField(
                ' ',
                TextEditingController(),
                '회',
                width: 60,
              ),
              SizedBox(width: 10),
              _buildButtonField(
                '재계약',
                () {},
                width: 100,
                color: const Color(0xFF34C759),
              ),
            ],
          ),
          _buildClickInputField('신규판매자', TextEditingController(), width: 150),
          _buildInputField('소개자', TextEditingController(), width: 150),
          _buildInputField('계약전계약처', TextEditingController(), width: 200),
          _buildDateField('상태변경일', TextEditingController(), width: 150),
          _buildClickInputField('담당권역', TextEditingController(), width: 150),
        ],
      ),
    ]);
  }

  // 월정료
  Widget _buildMonthlyFeeSection(bool isNarrow, bool isVeryNarrow) {
    return _buildSection('월정료', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildInputField('월정료', TextEditingController(), width: 120),
          _buildInputField('VAT포함', TextEditingController(), width: 120),
          _buildInputField('total월정료', TextEditingController(), width: 120),
          _buildInputField('totalVAT포함', TextEditingController(), width: 120),
          _buildInputField('cctv월정료', TextEditingController(), width: 120),
          _buildInputField('방범회사부담공사비', TextEditingController(), width: 120),
          _buildInputField('cctv회사부담공사비', TextEditingController(), width: 120),
          _buildInputField('전환위약금', TextEditingController(), width: 120),
          _buildInputField('철거공사비', TextEditingController(), width: 120),
          _buildInputField('긴급출동비', TextEditingController(), width: 120),
          _buildInputField('설치공사비', TextEditingController(), width: 120),
          _buildInputField('보증금', TextEditingController(), width: 120),
          _buildInputField('통합건수', TextEditingController(), width: 80),
        ],
      ),
    ]);
  }

  // 기타항목
  Widget _buildOtherItemsSection(bool isNarrow, bool isVeryNarrow) {
    return _buildSection('기타항목', [
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildClickInputField('사용자정의A', TextEditingController(), width: 150),
          _buildClickInputField('사용자정의B', TextEditingController(), width: 150),
          _buildLabelField('사이트타입', '', width: 150),
          _buildInputField('종사업장코드', TextEditingController(), width: 150),
          _buildDateField('재개시예정월', TextEditingController(), width: 150),
          _buildDateField('승계일자', TextEditingController(), width: 150),
          _buildRadioField('기기회수여부', 'N', ['Y', 'N'], (val) {}, width: 200),
          _buildInputWithSuffixField(
            '전환위약기간',
            TextEditingController(),
            '개월',
            width: 150,
          ),
        ],
      ),
    ]);
  }

  // 고객메모사항
  Widget _buildCustomerMemoSection() {
    return _buildSection('고객메모사항', [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            maxLines: 5,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              hintText: '메모를 입력하세요...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF007AFF),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 44,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '저장',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 120,
          height: 44,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF86868B),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '취소',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    double? width,
  }) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F5F7) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
          ),
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // 공통 섹션 빌더
  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Label 필드 (읽기전용)
  Widget _buildLabelField(String label, String value, {double? width}) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
          ),
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // Combobox 필드
  Widget _buildComboboxField(
    String label,
    List<String> items,
    String value, {
    double? width,
  }) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(
              left: 12,
              top: 8,
              right: 6,
              bottom: 8,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: (value) {},
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // 주소 필드 (돋보기 버튼 포함)
  Widget _buildClickInputField(
    String label,
    TextEditingController controller, {
    double? width,
  }) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 6),
        ] else ...[
          const SizedBox(height: 18), // 레이블 높이만큼 패딩
        ],
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: InkWell(
                onTap: () {
                  // 주소 검색 기능
                },
                child: const Icon(
                  Icons.search,
                  size: 16,
                  color: Color(0xFF007AFF),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // DatePicker 필드
  Widget _buildDateField(
    String label,
    TextEditingController controller, {
    double? width,
  }) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: InkWell(
                onTap: () {
                  // 주소 검색 기능
                },
                child: const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF86868B),
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 0,
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              controller.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            }
          },
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // 주소 입력 필드 (돋보기 버튼 포함)
  Widget _buildAddressRow(
    String label,
    TextEditingController addressController,
    TextEditingController zipController,
    bool isVeryNarrow,
  ) {
    if (isVeryNarrow) {
      // 매우 좁은 화면: 세로로 배치
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF86868B),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF007AFF),
                ),
                onPressed: () {
                  // 주소 검색 기능
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: addressController,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF007AFF),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '우편번호',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF86868B),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: zipController,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // 넓은 화면: 가로로 배치
      return Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF86868B),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 20, color: Color(0xFF007AFF)),
            onPressed: () {
              // 주소 검색 기능
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: addressController,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF007AFF),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '우편번호',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF86868B),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: zipController,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1D1D1F),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF007AFF),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // 이메일 필드 (input @ input + combobox)
  Widget _buildEmailField({double? width}) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '전자계산서이메일',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('@', style: TextStyle(fontSize: 13)),
            ),
            Expanded(
              child: TextFormField(
                style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                value: '직접입력',
                style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.only(
                    left: 12,
                    top: 8,
                    right: 6,
                    bottom: 8,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'nate.com', child: Text('nate.com')),
                  DropdownMenuItem(value: '직접입력', child: Text('직접입력')),
                  DropdownMenuItem(
                    value: 'naver.com',
                    child: Text('naver.com'),
                  ),
                  DropdownMenuItem(
                    value: 'gmail.com',
                    child: Text('gmail.com'),
                  ),
                  DropdownMenuItem(value: 'daum.net', child: Text('daum.net')),
                ],
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // 버튼 필드
  Widget _buildButtonField(
    String label,
    VoidCallback onPressed, {
    double? width,
    Color? color,
  }) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22), // 레이블 높이만큼 패딩
        SizedBox(
          height: 32,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color ?? const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(label, style: const TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // Checkbox 필드
  Widget _buildCheckboxField(
    String label,
    bool value,
    Function(bool?) onChanged, {
    double? width,
  }) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18), // 레이블 높이만큼 패딩
        Row(
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF007AFF),
            ),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // Radio 필드
  Widget _buildRadioField(
    String label,
    String groupValue,
    List<String> options,
    Function(String?) onChanged, {
    double? width,
  }) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: options.map((option) {
            return Row(
              children: [
                Radio(
                  value: option,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF007AFF),
                ),
                Text(option, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 12),
              ],
            );
          }).toList(),
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }

  // Input with suffix 필드 (예: "개월", "회")
  Widget _buildInputWithSuffixField(
    String label,
    TextEditingController controller,
    String suffix, {
    double? width,
  }) {
    Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF86868B),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1D1D1F)),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF007AFF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(suffix, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: field);
    }
    return field;
  }
}
