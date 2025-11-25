import 'package:flutter/material.dart';
import '../theme.dart';

/// 테이블 컬럼 설정 클래스
class TableColumnConfig {
  final String header; // 컬럼 헤더 텍스트
  final int flex; // Expanded의 flex 값
  final TextAlign textAlign; // 텍스트 정렬
  final String Function(dynamic data)? valueBuilder; // 데이터에서 값을 추출하는 함수
  final Widget Function(dynamic data, String value)?
      cellBuilder; // 커스텀 셀 위젯 빌더 (옵션)

  const TableColumnConfig({
    required this.header,
    this.flex = 1,
    this.textAlign = TextAlign.center,
    this.valueBuilder,
    this.cellBuilder,
  });
}

/// 공통 데이터 테이블 위젯
class CommonDataTable extends StatelessWidget {
  final String title; // 테이블 제목
  final List<TableColumnConfig> columns; // 컬럼 설정 리스트
  final List<dynamic> data; // 실제 데이터 리스트
  final String emptyMessage; // 데이터 없을 때 메시지
  final Widget? headerAction; // 제목 옆 추가 버튼 (옵션)
  final bool showStripedRows; // 줄무늬 행 표시 여부
  final String? searchQuery; // 검색어 (하이라이트용, 옵션)

  const CommonDataTable({
    super.key,
    required this.title,
    required this.columns,
    required this.data,
    this.emptyMessage = '데이터가 없습니다.',
    this.headerAction,
    this.showStripedRows = true,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
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
          // 제목 & 액션 버튼 영역
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF252525),
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (headerAction != null) ...[
                const SizedBox(width: 12),
                headerAction!,
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 테이블 헤더
          _buildTableHeader(),

          // 테이블 데이터
          if (data.isEmpty)
            _buildEmptyState()
          else
            ...data.asMap().entries.map((entry) {
              return _buildTableRow(entry.key, entry.value);
            }),
        ],
      ),
    );
  }

  /// 테이블 헤더 빌드
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          return Expanded(
            flex: column.flex,
            child: Text(
              column.header,
              textAlign: column.textAlign,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 빈 상태 빌드
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
        ),
      ),
      child: Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            color: Color(0xFF8D8D8D),
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// 테이블 행 빌드
  Widget _buildTableRow(int index, dynamic rowData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: showStripedRows && index % 2 == 0
            ? const Color(0xFFF5F5F5)
            : const Color(0xFFFFFFFF),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          final value = column.valueBuilder?.call(rowData) ?? '-';

          // 커스텀 셀 빌더가 있으면 사용
          if (column.cellBuilder != null) {
            return Expanded(
              flex: column.flex,
              child: column.cellBuilder!(rowData, value),
            );
          }

          // 기본 텍스트 셀
          return Expanded(
            flex: column.flex,
            child: Text(
              value,
              textAlign: column.textAlign,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
