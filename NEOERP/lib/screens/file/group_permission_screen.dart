import 'package:flutter/material.dart';

class GroupPermissionScreen extends StatefulWidget {
  const GroupPermissionScreen({super.key});

  @override
  State<GroupPermissionScreen> createState() => _GroupPermissionScreenState();
}

class _GroupPermissionScreenState extends State<GroupPermissionScreen> {
  String _selectedGroup = 'BM 사용자';

  final List<String> _groups = [
    'BM 사용자',
    '관리 사용자',
    '일반 사용자',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F7),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '프로그램 메뉴/보고서 사용권한 지정',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('사용자 그룹', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedGroup,
                items: _groups.map((String group) {
                  return DropdownMenuItem<String>(
                    value: group,
                    child: Text(group, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGroup = newValue!;
                  });
                },
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text('닫기', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                _buildPermissionSection('메뉴 권한설정'),
                const SizedBox(width: 16),
                _buildPermissionSection('보고서 권한설정'),
                const SizedBox(width: 16),
                _buildPermissionSection('세부 권한설정'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(String title) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(60, 30),
                        ),
                        child: const Text('전체해제', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(60, 30),
                        ),
                        child: const Text('전체선택', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildPermissionItem('코드설정', true, true, true),
                  _buildPermissionItem('사용자관리', false, true, true),
                  _buildPermissionItem('그룹권한설정', true, false, true),
                  _buildPermissionItem('기관코드설정', true, true, false),
                  _buildPermissionItem('고객설정관리', false, false, true),
                  _buildPermissionItem('도시파일등록', true, false, false),
                  _buildPermissionItem('고객정보내역', false, true, true),
                  _buildPermissionItem('계산서발행', true, true, true),
                  _buildPermissionItem('영업활동출력', false, true, false),
                  _buildPermissionItem('메시지발송', true, false, true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(double.infinity, 32),
                ),
                child: Text(
                  '${title.split(' ')[0]} 저장',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
    String title,
    bool read,
    bool write,
    bool delete,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Checkbox(
            value: read,
            onChanged: (value) {},
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Checkbox(
            value: write,
            onChanged: (value) {},
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Checkbox(
            value: delete,
            onChanged: (value) {},
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
