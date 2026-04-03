import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';
import 'package:chat_app/modules/truck_chat/services/group_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMemberDialog extends StatefulWidget {
  final String groupId;
  final List<String> initialProfileIds;

  const AddMemberDialog({
    super.key,
    required this.groupId,
    required this.initialProfileIds,
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<UserProfileModel> _users = [];
  List<UserProfileModel> _selectedUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;
    try {
      setState(() => _isLoading = true);
      final res = await GroupService().getMembers();
      if (res.status) {
        final fetched = res.data?.users ?? [];
        final preSelected = fetched
            .where(
              (u) => u.id != null && widget.initialProfileIds.contains(u.id!),
            )
            .toList();
        setState(() {
          _users = fetched;
          _selectedUsers = preSelected;
        });
      } else {
        AppSnackbar.error(res.message);
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<UserProfileModel> get _filteredUsers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      final name = (u.username ?? '').toLowerCase();
      final driverNo = (u.user?.driverNumber ?? '').toLowerCase();
      return name.contains(q) || driverNo.contains(q);
    }).toList();
  }

  Future<void> _submit() async {
    if (_selectedUsers.isEmpty) {
      AppSnackbar.error("Please select at least one member.");
      return;
    }
    try {
      setState(() => _isSubmitting = true);
      final ids = _selectedUsers
          .map((u) => u.id)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      final res = await GroupService().addGroupMembers(
        groupId: widget.groupId,
        membersCsv: ids.join(','),
      );
      if (res.status) {
        Get.back(result: true);
        AppSnackbar.success("Members added successfully.");
      } else {
        AppSnackbar.error(res.message);
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.group_add_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add members to group",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Search and select one or more drivers to add.",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: TextStyle(color: Colors.black),
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: "Search by name or driver number...",
                              prefixIcon: const Icon(Icons.search, size: 18),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${_selectedUsers.length} selected",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Builder(
                              builder: (_) {
                                final list = _filteredUsers;
                                if (list.isEmpty) {
                                  return Center(
                                    child: Text(
                                      "No members found",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, index) {
                                    final user = list[index];
                                    final selected = _selectedUsers.contains(
                                      user,
                                    );
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (selected) {
                                            _selectedUsers.remove(user);
                                          } else {
                                            _selectedUsers.add(user);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: selected,
                                              activeColor: AppColors.primary,
                                              onChanged: (_) {
                                                setState(() {
                                                  if (selected) {
                                                    _selectedUsers.remove(user);
                                                  } else {
                                                    _selectedUsers.add(user);
                                                  }
                                                });
                                              },
                                            ),
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppColors.primary
                                                  .withOpacity(0.08),
                                              child: Text(
                                                (user.username ?? "?")
                                                    .characters
                                                    .take(1)
                                                    .toString()
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.username ?? "-",
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "${user.user?.driverNumber ?? ''} • ${user.user?.phoneNumber ?? ''}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text("Add members"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
