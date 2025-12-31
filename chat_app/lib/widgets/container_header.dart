import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContainerHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? searchHint;
  final bool showSearch;
  final bool showActionButton;
  final String? actionButtonText;
  final IconData? actionButtonIcon;
  final VoidCallback? onActionPressed;
  final VoidCallback? onSearchChanged;
  final List<Widget>? trailingActions;
  final bool isTrailingActions;
  final Color? primaryColor;
  final bool showDivider;

  const ContainerHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchHint,
    this.showSearch = false,
    this.showActionButton = false,
    this.actionButtonText,
    this.actionButtonIcon,
    this.onActionPressed,
    this.onSearchChanged,
    this.trailingActions,
    this.isTrailingActions = false,
    this.primaryColor,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFF4A154B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Actions Section
            Row(
              children: [
                // Search Field
                if (showSearch)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: showSearch ? 280 : 0,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (value) => onSearchChanged?.call(),
                            decoration: InputDecoration(
                              hintText: searchHint ?? "Search...",
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (showSearch && (showActionButton || trailingActions != null))
                  const SizedBox(width: 12),

                // Action Button
                if (showActionButton)
                  ElevatedButton.icon(
                    onPressed: onActionPressed,
                    icon: Icon(actionButtonIcon ?? Icons.add, size: 18),
                    label: Text(
                      actionButtonText ?? "Add New",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                  ),

                // Additional Actions
                if (trailingActions != null && trailingActions!.isNotEmpty) ...[
                  if (showActionButton) const SizedBox(width: 8),
                  ...trailingActions!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final action = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                      child: action,
                    );
                  }),
                ],

                // Overflow Menu
                if ((trailingActions == null || trailingActions!.isEmpty) &&
                    isTrailingActions)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'filter',
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, size: 18),
                            SizedBox(width: 8),
                            Text("Filter"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 18),
                            SizedBox(width: 8),
                            Text("Export"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 18),
                            SizedBox(width: 8),
                            Text("Refresh"),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      // Handle menu selection
                    },
                  ),
              ],
            ),
          ],
        ),

        if (showDivider) ...[
          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        ],
      ],
    );
  }
}
