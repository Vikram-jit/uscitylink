import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DataTableConfig<T> {
  final String title;
  final List<DataColumn> columns;
  final List<DataRow> Function(List<T> data) buildRows;
  final int totalItems;
  final int currentPage;
  final int itemsPerPage;
  final ValueChanged<int>? onPageChanged;
  final VoidCallback? onExport;
  final VoidCallback? onFilter;
  final VoidCallback? onRefresh;
  final Widget? emptyState;
  final bool showHeader;
  final bool showPagination;
  final bool showActions;
  final Color? primaryColor;

  DataTableConfig({
    required this.title,
    required this.columns,
    required this.buildRows,
    required this.totalItems,
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.onPageChanged,
    this.onExport,
    this.onFilter,
    this.onRefresh,
    this.emptyState,
    this.showHeader = true,
    this.showPagination = true,
    this.showActions = true,
    this.primaryColor,
  });
}

class TableContainer<T> extends StatefulWidget {
  final List<T> data;
  final DataTableConfig<T> config;

  const TableContainer({super.key, required this.data, required this.config});

  @override
  State<TableContainer<T>> createState() => _TableContainerState<T>();
}

class _TableContainerState<T> extends State<TableContainer<T>> {
  // Fixed: Changed to TableContainer<T>
  late int _currentPage;
  late int _totalPages;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.config.currentPage;
    _totalPages = (widget.config.totalItems / widget.config.itemsPerPage)
        .ceil();
  }

  @override
  void didUpdateWidget(TableContainer<T> oldWidget) {
    // Fixed: Added type parameter
    super.didUpdateWidget(oldWidget);
    _totalPages = (widget.config.totalItems / widget.config.itemsPerPage)
        .ceil();
    if (_currentPage > _totalPages && _totalPages > 0) {
      _currentPage = _totalPages;
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      widget.config.onPageChanged?.call(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.config.primaryColor ?? const Color(0xFF4A154B);
    final displayData = widget.data;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          if (widget.config.showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.config.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (widget.config.showActions)
                    Row(
                      children: [
                        if (widget.config.onFilter != null)
                          IconButton(
                            onPressed: widget.config.onFilter,
                            icon: Icon(
                              Icons.filter_list,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            tooltip: "Filter",
                          ),
                        if (widget.config.onExport != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: widget.config.onExport,
                            icon: Icon(
                              Icons.download,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            tooltip: "Export",
                          ),
                        ],
                        if (widget.config.onRefresh != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: widget.config.onRefresh,
                            icon: Icon(
                              Icons.refresh,
                              size: 20,
                              color: Colors.grey.shade600,
                            ),
                            tooltip: "Refresh",
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),

          if (widget.config.showHeader)
            Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

          // Table Content
          Expanded(
            child: displayData.isEmpty
                ? widget.config.emptyState ??
                      _buildDefaultEmptyState(widget.config.title)
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                        ),
                        child: DataTable(
                          dataRowMinHeight: 64,
                          dataRowMaxHeight: 64,
                          headingRowHeight: 48,
                          horizontalMargin: 24,
                          columnSpacing: 32,
                          dividerThickness: 0,
                          headingRowColor:
                              MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) =>
                                    Colors.grey.shade50,
                              ),
                          columns: widget.config.columns,
                          rows: widget.config.buildRows(displayData),
                        ),
                      ),
                    ),
                  ),
          ),

          // Pagination Footer
          if (widget.config.showPagination && _totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Showing ${_getStartIndex() + 1}-${_getEndIndex()} of ${widget.config.totalItems} items",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentPage > 1
                            ? () => _goToPage(_currentPage - 1)
                            : null,
                        icon: Icon(
                          Icons.chevron_left,
                          color: _currentPage > 1
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPageNumbers(),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _currentPage < _totalPages
                            ? () => _goToPage(_currentPage + 1)
                            : null,
                        icon: Icon(
                          Icons.chevron_right,
                          color: _currentPage < _totalPages
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
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

  Widget _buildPageNumbers() {
    final pagesToShow = _generatePageNumbers();

    return Row(
      children: pagesToShow.map((page) {
        final isCurrent = page == _currentPage;
        final isEllipsis = page == -1;

        if (isEllipsis) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "...",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _goToPage(page),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent
                  ? widget.config.primaryColor ?? const Color(0xFF4A154B)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: !isCurrent
                  ? Border.all(color: Colors.grey.shade300)
                  : null,
            ),
            child: Text(
              page.toString(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isCurrent ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<int> _generatePageNumbers() {
    final List<int> pages = [];
    const int maxVisiblePages = 5;

    if (_totalPages <= maxVisiblePages) {
      // Show all pages
      for (int i = 1; i <= _totalPages; i++) {
        pages.add(i);
      }
    } else {
      // Show first page, last page, current page and neighbors
      if (_currentPage <= 3) {
        // Near the beginning
        for (int i = 1; i <= 4; i++) {
          pages.add(i);
        }
        pages.add(-1); // Ellipsis
        pages.add(_totalPages);
      } else if (_currentPage >= _totalPages - 2) {
        // Near the end
        pages.add(1);
        pages.add(-1); // Ellipsis
        for (int i = _totalPages - 3; i <= _totalPages; i++) {
          pages.add(i);
        }
      } else {
        // In the middle
        pages.add(1);
        pages.add(-1); // Ellipsis
        for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
          pages.add(i);
        }
        pages.add(-1); // Ellipsis
        pages.add(_totalPages);
      }
    }

    return pages;
  }

  int _getStartIndex() {
    return (_currentPage - 1) * widget.config.itemsPerPage;
  }

  int _getEndIndex() {
    final end = _currentPage * widget.config.itemsPerPage;
    return end > widget.config.totalItems ? widget.config.totalItems : end;
  }

  Widget _buildDefaultEmptyState(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No data available",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "There are no items to display in $title",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
