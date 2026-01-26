import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/search_panel.dart';
import '../services/api_service.dart';
import '../services/selected_customer_service.dart';

class CustomerSearchPanel extends StatefulWidget {
  final Function(SearchPanel?) onCustomerSelected;

  const CustomerSearchPanel({super.key, required this.onCustomerSelected});

  @override
  State<CustomerSearchPanel> createState() => _CustomerSearchPanelState();
}

class _CustomerSearchPanelState extends State<CustomerSearchPanel> {
  String selectedFilter = '상호';
  String selectedSort = '상호정렬';
  String searchQuery = '';
  SearchPanel? selectedCustomer;
  List<SearchPanel> customers = [];
  bool isLoading = false;
  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();
  final _customerService = SelectedCustomerService(); // 서비스 추가

  final List<String> filters = ['상호', '고객번호', '대표자', '주소', '전화번호', '사용자HP'];

  final List<String> sorts = ['상호정렬', '번호정렬'];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedCustomers = await DatabaseService.getCustomers();
      setState(() {
        customers = loadedCustomers;
        isLoading = false;
      });
    } catch (e) {
      print('고객 로드 오류: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Debounce를 적용한 검색 메서드
  void _onSearchChanged(String query) {
    // 기존 타이머가 있다면 취소
    _debounceTimer?.cancel();

    // 새로운 타이머 시작 (500ms 후 실행)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          searchQuery = query;
        });
        // 검색어가 비어있으면 초기 고객 목록 로드
        if (query.isEmpty) {
          _loadCustomers();
        }
        // 사용자HP는 서버에서만 검색 가능하므로 1글자 이상이면 즉시 검색
        // 다른 필터는 2글자 이상일 때만 서버 API 호출
        else if (selectedFilter == '사용자HP' && query.isNotEmpty) {
          _searchCustomers(query);
        } else if (query.length >= 2) {
          _searchCustomers(query);
        }
      }
    });

    // 즉시 UI는 업데이트 (로컬 필터링을 위해)
    setState(() {
      searchQuery = query;
    });
  }

  // 서버에서 검색하는 메서드
  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final searchResults = await DatabaseService.searchCustomers(
        filterType: selectedFilter,
        query: query,
        sortType: selectedSort,
        count: 100,
      );

      if (mounted) {
        setState(() {
          customers = searchResults;
          isLoading = false;
        });
      }
    } catch (e) {
      print('서버 검색 오류: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<SearchPanel> get filteredCustomers {
    // 사용자HP 검색은 서버에서만 처리되므로 로컬 필터링 제외
    var filtered = customers.where((customer) {
      // 사용자HP 필터인 경우 로컬 필터링 생략 (서버에서 이미 필터링됨)
      if (selectedFilter == '사용자HP') {
        return true;
      }
      return customer.matchesFilter(selectedFilter, searchQuery);
    }).toList();

    if (selectedSort == '번호정렬') {
      filtered.sort(
        (a, b) =>
            a.controlManagementNumber.compareTo(b.controlManagementNumber),
      );
    } else {
      filtered.sort(
        (a, b) => a.controlBusinessName.compareTo(b.controlBusinessName),
      );
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: context.colors.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilters(),
          _buildSortButtons(),
          Expanded(child: _buildCustomerList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: context.colors.gray10,
        border: Border(
          bottom: BorderSide(color: context.colors.dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 20, color: context.colors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '고객 검색',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 20,
              color: context.colors.textSecondary,
            ),
            onPressed: _loadCustomers,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '2글자 이상 검색',
          hintStyle: TextStyle(color: context.colors.textSecondary),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: context.colors.textSecondary,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.colors.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: context.colors.selectedColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: context.colors.cardBackground,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '필터',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: filters.map((filter) {
              final isSelected = filter == selectedFilter;
              return InkWell(
                onTap: () {
                  setState(() {
                    selectedFilter = filter;
                  });
                  // 필터 변경 시 현재 검색어로 다시 검색
                  if (_searchController.text.isNotEmpty) {
                    if (filter == '사용자HP' &&
                        _searchController.text.isNotEmpty) {
                      _searchCustomers(_searchController.text);
                    } else if (_searchController.text.length >= 2) {
                      _searchCustomers(_searchController.text);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.selectedColor
                        : context.colors.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? context.colors.selectedColor
                          : context.colors.dividerColor,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.colors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: sorts.map((sort) {
          final isSelected = sort == selectedSort;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedSort = sort;
                  });
                  // 정렬 변경 시 현재 검색어로 다시 검색
                  if (_searchController.text.isEmpty) {
                    _loadCustomers();
                  } else if (_searchController.text.isNotEmpty) {
                    if (selectedFilter == '사용자HP' &&
                        _searchController.text.isNotEmpty) {
                      _searchCustomers(_searchController.text);
                    } else if (_searchController.text.length >= 2) {
                      _searchCustomers(_searchController.text);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.selectedColor
                        : context.colors.cardBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? context.colors.selectedColor
                          : context.colors.dividerColor,
                    ),
                  ),
                  child: Text(
                    sort,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.colors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomerList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.selectedColor),
      );
    }

    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '고객 데이터가 없습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final filtered = filteredCustomers;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: context.colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final customer = filtered[index];
        final isSelected = customer == selectedCustomer;

        return InkWell(
          onTap: () {
            // 편집 중인지 확인
            if (!_customerService.canLeave(() {
              // 확인 후 실행할 로직
              setState(() {
                selectedCustomer = customer;
              });
              // 전역 서비스에 고객 정보 저장
              SelectedCustomerService().selectCustomer(customer);
              widget.onCustomerSelected(customer);
            })) {
              // 편집 중이므로 여기서는 아무것도 하지 않음
              // canLeave가 다이얼로그를 표시함
              return;
            }

            // 편집 중이 아니면 바로 실행
            setState(() {
              selectedCustomer = customer;
            });
            // 전역 서비스에 고객 정보 저장
            SelectedCustomerService().selectCustomer(customer);
            widget.onCustomerSelected(customer);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colors.selectedColor.withOpacity(0.3)
                  : context.colors.gray10,
              border: Border(
                bottom: BorderSide(
                  color: context.colors.dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.selectedColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        customer.controlManagementNumber,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        customer.controlBusinessName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          customer.customerStatusName ?? '로드오류',
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getStatusColor(
                            customer.customerStatusName ?? '로드오류',
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        customer.customerStatusName ?? '로드오류',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(
                            customer.customerStatusName ?? '로드오류',
                          ),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  customer.propertyAddress,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    // 상태에 따른 색상 구분
    if (status.contains('정상') || status.contains('관제중')) {
      return context.colors.green;
    } else if (status.contains('보류') || status.contains('대기')) {
      return context.colors.orange;
    } else if (status.contains('해지') || status.contains('중지')) {
      return context.colors.red;
    }
    return context.colors.textSecondary;
  }
}
