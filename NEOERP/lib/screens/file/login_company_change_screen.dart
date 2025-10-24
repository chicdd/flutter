import 'package:flutter/material.dart';

class LoginCompanyChangeScreen extends StatefulWidget {
  const LoginCompanyChangeScreen({super.key});

  @override
  State<LoginCompanyChangeScreen> createState() =>
      _LoginCompanyChangeScreenState();
}

class _LoginCompanyChangeScreenState extends State<LoginCompanyChangeScreen> {
  String? _selectedCompany;

  final List<String> _companies = [
    '서대문포콤',
    '한국안전시스템',
    '순천씨원',
    '한세시큐리티',
  ];

  void _changeCompany() {
    if (_selectedCompany == null) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedCompany로 변경되었습니다'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F7),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Text(
                  '회사구분',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCompany,
                      isExpanded: true,
                      hint: const Text('선택하세요'),
                      items: _companies.map((String company) {
                        return DropdownMenuItem<String>(
                          value: company,
                          child: Text(company),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCompany = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 100,
                height: 36,
                child: OutlinedButton(
                  onPressed: _changeCompany,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D1D1F),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('변 경', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                height: 36,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D1D1F),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('취 소', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
