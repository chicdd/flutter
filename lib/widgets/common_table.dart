import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme.dart';
import 'custom_top_bar.dart'; // HighlightedText import

/// 열 구분선 위젯 (공통 함수)
Widget buildColumnDivider() {
  return Container(
    width: 8,
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
        right: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
    ),
  );
}

/// 테이블 셀 위젯 (공통 함수)
Widget buildTableCell({
  required String value,
  required Map<int, double> columnWidths,
  required int columnIndex,
  String searchQuery = '',
}) {
  return Container(
    width: columnWidths[columnIndex],
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Center(
      child: HighlightedText(
        text: value,
        query: searchQuery,
        style: const TextStyle(
          color: Color(0xFF252525),
          fontSize: 15,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
  );
}

/// 테이블 컬럼 설정 클래스
class TableColumnConfig {
  final String header; // 컬럼 헤더 텍스트
  final int flex; // Expanded의 flex 값
  final double? width; // 고정 너비 (가로 스크롤 사용 시)
  final TextAlign textAlign; // 텍스트 정렬
  final String Function(dynamic data)? valueBuilder; // 데이터에서 값을 추출하는 함수
  final Widget Function(dynamic data, String value)?
  cellBuilder; // 커스텀 셀 위젯 빌더 (옵션)

  const TableColumnConfig({
    required this.header,
    this.flex = 1,
    this.width,
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
  //final bool enableHorizontalScroll; // 가로 스크롤 활성화 여부
  final ScrollController? scrollController; // 세로 스크롤 컨트롤러 (옵션)
  final ScrollController? horizontalScrollController; // 가로 스크롤 컨트롤러 (옵션)

  const CommonDataTable({
    super.key,
    required this.title,
    required this.columns,
    required this.data,
    this.emptyMessage = '데이터가 없습니다.',
    this.headerAction,
    this.showStripedRows = true,
    this.searchQuery,
    //this.enableHorizontalScroll = false,
    this.scrollController,
    this.horizontalScrollController,
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

          // 가로 스크롤 활성화 시
          // if (enableHorizontalScroll)
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: SingleChildScrollView(
                controller: horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _calculateTotalWidth(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 테이블 헤더
                      _buildTableHeader(),

                      // 테이블 데이터
                      Expanded(
                        child: data.isEmpty
                            ? _buildEmptyState()
                            : ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context)
                                    .copyWith(
                                      dragDevices: {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind.mouse,
                                      },
                                    ),
                                child: ListView.builder(
                                  controller: scrollController,
                                  itemCount: data.length,
                                  itemBuilder: (context, index) {
                                    return _buildTableRow(index, data[index]);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // else
          //   // 가로 스크롤 비활성화 시 세로 스크롤만 활성화
          //   Expanded(
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         // 테이블 헤더
          //         _buildTableHeader(),
          //
          //         // 테이블 데이터
          //         Expanded(
          //           child: data.isEmpty
          //               ? _buildEmptyState()
          //               : ScrollConfiguration(
          //                   behavior: ScrollConfiguration.of(context).copyWith(
          //                     dragDevices: {
          //                       PointerDeviceKind.touch,
          //                       PointerDeviceKind.mouse,
          //                     },
          //                   ),
          //                   child: ListView.builder(
          //                     controller: scrollController,
          //                     itemCount: data.length,
          //                     itemBuilder: (context, index) {
          //                       return _buildTableRow(index, data[index]);
          //                     },
          //                   ),
          //                 ),
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }

  /// 전체 테이블 너비 계산
  double _calculateTotalWidth() {
    //if (!enableHorizontalScroll) return 0;

    double totalWidth = 32; // 좌우 패딩
    for (var column in columns) {
      if (column.width != null) {
        totalWidth += column.width!;
      }
    }
    return totalWidth;
  }

  /// 테이블 헤더 빌드
  Widget _buildTableHeader() {
    return Container(
      width: _calculateTotalWidth(),
      //width: enableHorizontalScroll ? _calculateTotalWidth() : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          final child = Text(
            column.header,
            textAlign: column.textAlign,
            style: const TextStyle(
              color: Color(0xFF252525),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          );

          // 가로 스크롤 활성화 시 고정 너비 사용
          // if (enableHorizontalScroll && column.width != null) {
          //   return SizedBox(width: column.width, child: child);
          // }

          // 일반 모드는 Expanded 사용
          return Expanded(flex: column.flex, child: child);
        }).toList(),
      ),
    );
  }

  /// 빈 상태 빌드
  Widget _buildEmptyState() {
    return Container(
      width: _calculateTotalWidth(),
      //width: enableHorizontalScroll ? _calculateTotalWidth() : null,
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
      width: _calculateTotalWidth(),
      //width: enableHorizontalScroll ? _calculateTotalWidth() : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: showStripedRows && index % 2 == 0
            ? const Color(0xFFFFFFFF)
            : const Color(0xFFF5F5F5),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          final value = column.valueBuilder?.call(rowData) ?? '-';

          Widget child;

          // 커스텀 셀 빌더가 있으면 사용
          if (column.cellBuilder != null) {
            child = column.cellBuilder!(rowData, value);
          } else {
            // 기본 텍스트 셀
            child = Text(
              value,
              textAlign: column.textAlign,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            );
          }

          // 가로 스크롤 활성화 시 고정 너비 사용
          // if (enableHorizontalScroll && column.width != null) {
          //   return SizedBox(width: column.width, child: child);
          // }

          // 일반 모드는 Expanded 사용
          return Expanded(flex: column.flex, child: child);
        }).toList(),
      ),
    );
  }
}

/// 공통 테이블 위젯 구성
Widget buildTable<T>({
  required BuildContext context,
  required String title,
  required List<T> dataList,
  required List<TableColumnConfig> columns,
  required Map<int, double> columnWidths,
  required void Function(int columnIndex, double newWidth) onColumnResize,
  String searchQuery = '',
  bool showTotalCount = false,
  VoidCallback? onAdd,
  String addButtonLabel = '추가',
  int? pagingTotalcount,
  ScrollController? verticalScrollController,
}) {
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
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF252525),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showTotalCount) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4318FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '총 ${(pagingTotalcount != null && pagingTotalcount != 0) ? pagingTotalcount : dataList.length}건',
                  style: const TextStyle(
                    color: Color(0xFF4318FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (onAdd != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onAdd,
                      label: Text(addButtonLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.selectedColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: dataList.isEmpty
              ? const Center(
                  child: Text(
                    '조회된 데이터가 없습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : buildResizableTable(
                  context: context,
                  dataList: dataList,
                  columns: columns,
                  columnWidths: columnWidths,
                  onColumnResize: onColumnResize,
                  searchQuery: searchQuery,
                  verticalScrollController: verticalScrollController,
                ),
        ),
      ],
    ),
  );
}

/// 크기 조절 가능한 테이블 (StatefulWidget으로 스크롤 동기화 처리)
class ResizableTableWidget<T> extends StatefulWidget {
  final List<T> dataList;
  final List<TableColumnConfig> columns;
  final Map<int, double> columnWidths;
  final ScrollController? headerScrollController;
  final ScrollController? bodyScrollController;
  final ScrollController? verticalScrollController;
  final void Function(int columnIndex, double newWidth) onColumnResize;
  final String searchQuery;

  const ResizableTableWidget({
    super.key,
    required this.dataList,
    required this.columns,
    required this.columnWidths,
    this.headerScrollController,
    this.bodyScrollController,
    this.verticalScrollController,
    required this.onColumnResize,
    this.searchQuery = '',
  });

  @override
  State<ResizableTableWidget<T>> createState() =>
      _ResizableTableWidgetState<T>();
}

class _ResizableTableWidgetState<T> extends State<ResizableTableWidget<T>> {
  bool _isSyncingScroll = false;

  late final ScrollController _internalHeaderController;
  late final ScrollController _internalBodyController;
  late final ScrollController _internalVerticalController;

  // 내부 생성 여부 플래그
  late final bool _ownsHeaderController;
  late final bool _ownsBodyController;
  late final bool _ownsVerticalController;

  // 실제 사용할 컨트롤러 (외부 or 내부)
  late final ScrollController _headerController;
  late final ScrollController _bodyController;
  late final ScrollController _verticalController;

  @override
  void initState() {
    super.initState();

    // ScrollController 초기화 (외부에서 전달하지 않으면 내부에서 생성)
    _ownsHeaderController = widget.headerScrollController == null;
    _ownsBodyController = widget.bodyScrollController == null;
    _ownsVerticalController = widget.verticalScrollController == null;

    if (_ownsHeaderController) {
      _internalHeaderController = ScrollController();
      _headerController = _internalHeaderController;
    } else {
      _headerController = widget.headerScrollController!;
    }

    if (_ownsBodyController) {
      _internalBodyController = ScrollController();
      _bodyController = _internalBodyController;
    } else {
      _bodyController = widget.bodyScrollController!;
    }

    if (_ownsVerticalController) {
      _internalVerticalController = ScrollController();
      _verticalController = _internalVerticalController;
    } else {
      _verticalController = widget.verticalScrollController!;
    }

    // 헤더와 바디 스크롤 동기화 리스너 추가
    _headerController.addListener(_syncHeaderScroll);
    _bodyController.addListener(_syncBodyScroll);
  }

  @override
  void dispose() {
    // 리스너 제거
    _headerController.removeListener(_syncHeaderScroll);
    _bodyController.removeListener(_syncBodyScroll);

    // 내부에서 생성한 컨트롤러만 dispose
    if (_ownsHeaderController) {
      _internalHeaderController.dispose();
    }
    if (_ownsBodyController) {
      _internalBodyController.dispose();
    }
    if (_ownsVerticalController) {
      _internalVerticalController.dispose();
    }

    super.dispose();
  }

  // 헤더 스크롤 동기화
  void _syncHeaderScroll() {
    if (_isSyncingScroll) return;
    _isSyncingScroll = true;

    if (_bodyController.hasClients &&
        _bodyController.offset != _headerController.offset) {
      _bodyController.jumpTo(_headerController.offset);
    }

    _isSyncingScroll = false;
  }

  // 바디 스크롤 동기화
  void _syncBodyScroll() {
    if (_isSyncingScroll) return;
    _isSyncingScroll = true;

    if (_headerController.hasClients &&
        _headerController.offset != _bodyController.offset) {
      _headerController.jumpTo(_bodyController.offset);
    }

    _isSyncingScroll = false;
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            controller: _headerController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: buildTableHeader(
              columns: widget.columns,
              columnWidths: widget.columnWidths,
              onColumnResize: widget.onColumnResize,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                controller: _bodyController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: buildTableBody(
                  dataList: widget.dataList,
                  columns: widget.columns,
                  columnWidths: widget.columnWidths,
                  searchQuery: widget.searchQuery,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 크기 조절 가능한 테이블 (래퍼 함수 - 하위 호환성 유지)
Widget buildResizableTable<T>({
  required BuildContext context,
  required List<T> dataList,
  required List<TableColumnConfig> columns,
  required Map<int, double> columnWidths,
  ScrollController? headerScrollController,
  ScrollController? bodyScrollController,
  ScrollController? verticalScrollController,
  required void Function(int columnIndex, double newWidth) onColumnResize,
  String searchQuery = '',
}) {
  return ResizableTableWidget<T>(
    dataList: dataList,
    columns: columns,
    columnWidths: columnWidths,
    headerScrollController: headerScrollController,
    bodyScrollController: bodyScrollController,
    verticalScrollController: verticalScrollController,
    onColumnResize: onColumnResize,
    searchQuery: searchQuery,
  );
}

/// 테이블 헤더
Widget buildTableHeader<T>({
  required List<TableColumnConfig> columns,
  required Map<int, double> columnWidths,
  required void Function(int columnIndex, double newWidth) onColumnResize,
}) {
  return Container(
    height: 45,
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
    child: Row(
      children: columns.asMap().entries.map((entry) {
        final columnIndex = entry.key;
        final column = entry.value;

        return Row(
          children: [
            Container(
              width: columnWidths[columnIndex],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                column.header,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF252525),
                ),
              ),
            ),
            // 크기 조절 핸들 (마지막 열 제외)
            if (columnIndex < columns.length - 1)
              buildResizeHandle(
                columnIndex: columnIndex,
                columnWidths: columnWidths,
                onColumnResize: onColumnResize,
              ),
          ],
        );
      }).toList(),
    ),
  );
}

/// 크기 조절 핸들
Widget buildResizeHandle({
  required int columnIndex,
  required Map<int, double> columnWidths,
  required void Function(int columnIndex, double newWidth) onColumnResize,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    child: GestureDetector(
      onHorizontalDragUpdate: (details) {
        final newWidth = (columnWidths[columnIndex]! + details.delta.dx).clamp(
          50.0,
          500.0,
        );
        onColumnResize(columnIndex, newWidth);
      },
      child: Container(
        width: 8,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
            right: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
          ),
        ),
      ),
    ),
  );
}

/// 테이블 바디 구성 (userzoneInfo.dart에서 이동)
Widget buildTableBody<T>({
  required List<T> dataList,
  required List<TableColumnConfig> columns,
  required Map<int, double> columnWidths,
  String searchQuery = '',
}) {
  return Column(
    children: List.generate(dataList.length, (index) {
      final data = dataList[index];
      final isEven = index % 2 == 0;

      return Container(
        height: 45,
        decoration: BoxDecoration(
          color: isEven ? Colors.white : const Color(0xFFFAFAFA),
          border: const Border(
            left: BorderSide(color: Color(0xFFE0E0E0)),
            right: BorderSide(color: Color(0xFFE0E0E0)),
            bottom: BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        child: Row(
          children: columns.asMap().entries.map((entry) {
            final columnIndex = entry.key;
            final column = entry.value;
            final value = column.valueBuilder?.call(data) ?? '';

            final cellWidget = column.cellBuilder != null
                ? column.cellBuilder!(data, value)
                : buildTableCell(
                    value: value,
                    columnWidths: columnWidths,
                    columnIndex: columnIndex,
                    searchQuery: searchQuery,
                  );

            return Row(
              children: [
                cellWidget,
                if (columnIndex < columns.length - 1) buildColumnDivider(),
              ],
            );
          }).toList(),
        ),
      );
    }),
  );
}
