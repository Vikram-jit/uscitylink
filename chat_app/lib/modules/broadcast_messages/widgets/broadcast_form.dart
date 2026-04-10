import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/local_media_preview.dart';
import 'package:chat_app/modules/broadcast_messages/broadcast_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class BroadcastForm extends StatelessWidget {
  final controller = Get.put(BroadcastFormController());

  BroadcastForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      // ✅ SingleChildScrollView prevents the Column overflow
      child: SingleChildScrollView(
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EBFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Broadcast Message',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1730),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Mode toggle ──
              Row(
                children: [
                  _ModeButton(label: 'Specific', value: 'specific'),
                  const SizedBox(width: 8),
                  _ModeButton(label: 'All', value: 'all'),
                ],
              ),

              const SizedBox(height: 16),

              // ── User section (specific mode) ──
              if (controller.mode.value == 'specific') ...[
                // Search field
                TextField(
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF1A1730),
                  ),
                  onChanged: controller.setSearch,
                  decoration: InputDecoration(
                    hintText: 'Search drivers…',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: const Color(0xFF9B97A8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: Color(0xFF9B97A8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ Fixed height box — no Flexible/Expanded inside Column
                SizedBox(
                  height: 220,
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.users.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: controller.scrollController,
                      itemCount:
                          controller.users.length +
                          (controller.hasMore.value ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == controller.users.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }

                        final user = controller.users[i];
                        final selected = controller.selectedUsers.contains(
                          user,
                        );

                        return _UserTile(
                          name: user.userProfile?.username ?? '—',
                          driverNo: user.userProfile?.user?.driverNumber ?? '—',
                          selected: selected,
                          onTap: () => controller.toggleUser(user),
                        );
                      },
                    );
                  }),
                ),
              ],

              const SizedBox(height: 10),

              // ── Selected chips ──
              if (controller.isAllSelected.value)
                _AllSelectedChip()
              else if (controller.selectedUsers.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: controller.selectedUsers.map((u) {
                    return _UserChip(
                      label: u.userProfile?.username ?? '—',
                      onRemove: () => controller.toggleUser(u),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 10),

              // ── Message field ──
              TextField(
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: const Color(0xFF1A1730),
                ),
                controller: controller.messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter message…',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: const Color(0xFF9B97A8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── File preview ──
              Obx(() {
                final file = controller.pendingFile.value;
                if (file == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LocalMediaPreview(
                    platformFile: file,
                    width: 120,
                    height: 120,
                    onRemove: () => controller.pendingFile.value = null,
                  ),
                );
              }),

              // ── Attach button ──
              GestureDetector(
                onTap: controller.pickFile,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.attach_file_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Attach file',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Send button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.sendMessage,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    'Send Message',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mode toggle button
// ─────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final String label;
  final String value;

  const _ModeButton({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BroadcastFormController>();

    return Expanded(
      child: Obx(() {
        final isSelected = controller.mode.value == value;

        return GestureDetector(
          onTap: () => controller.changeMode(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0EBFC) : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF9B97A8),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// User list tile
// ─────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final String name;
  final String driverNo;
  final bool selected;
  final VoidCallback onTap;

  const _UserTile({
    required this.name,
    required this.driverNo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            // Initials
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBFC),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name + driver no
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1730),
                    ),
                  ),
                  Text(
                    driverNo,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF9B97A8),
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: Color(0xFFD0C8E8), width: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Selected user chip
// ─────────────────────────────────────────────────────────────

class _UserChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _UserChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4a2a90),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// All selected chip
// ─────────────────────────────────────────────────────────────

class _AllSelectedChip extends StatelessWidget {
  const _AllSelectedChip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Column(
        children: [
          Container(
            height: 50,

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3DE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF639922).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: Color(0xFF3B6D11),
                ),
                const SizedBox(width: 6),
                Text(
                  'All users selected',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF27500A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
