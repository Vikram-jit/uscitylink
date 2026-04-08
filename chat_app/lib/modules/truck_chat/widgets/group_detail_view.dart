import 'package:chat_app/core/theme/colors.dart';
import 'package:chat_app/core/widgets/app_snackbar.dart';
import 'package:chat_app/modules/home/home_controller.dart';
import 'package:chat_app/modules/truck_chat/controller/group_controller.dart';
import 'package:chat_app/modules/truck_chat/controller/group_message_controller.dart';
import 'package:chat_app/modules/truck_chat/services/group_service.dart';
import 'package:chat_app/modules/truck_chat/widgets/add_member_dialog.dart';
import 'package:chat_app/models/truck_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({super.key});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  final GroupMessageController controller = Get.find<GroupMessageController>();
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  String? _lastGroupId;
  List<TruckModel> _trucks = [];
  TruckModel? _selectedTruck;
  bool _isTrucksLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    _fetchTrucks();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _syncFromGroup() {
    final group = controller.group.value;
    if (group.id == null) return;
    // Only sync when group changes, so user edits are not overwritten
    if (_lastGroupId != group.id) {
      _lastGroupId = group.id;
      nameController.text = group.name ?? "";
      descriptionController.text = group.description ?? "";

      if (group.type == 'truck' && _trucks.isNotEmpty) {
        TruckModel? match;
        for (final t in _trucks) {
          if (t.number == group.name) {
            match = t;
            break;
          }
        }
        _selectedTruck = match;
      }
    }
  }

  Future<void> _fetchTrucks() async {
    if (_isTrucksLoading) return;
    try {
      setState(() {
        _isTrucksLoading = true;
      });
      final res = await GroupService().truckList();
      if (res.status) {
        final list = res.data ?? [];
        final group = controller.group.value;

        TruckModel? match;
        if (group.type == 'truck' && group.name != null) {
          for (final t in list) {
            if (t.number == group.name) {
              match = t;
              break;
            }
          }
        }

        setState(() {
          _trucks = list;
          _selectedTruck = match;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTrucksLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final group = controller.group.value;
      final members = controller.memmbers;

      _syncFromGroup();

      final activeCount = members.where((m) => m.status == 'active').length;
      final inactiveCount = members.where((m) => m.status != 'active').length;

      return LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Group Details",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.type == 'truck'
                                          ? "Truck"
                                          : "Group Name",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    if (group.type == 'truck')
                                      (_isTrucksLoading
                                          ? const SizedBox(
                                              height: 40,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : DropdownButtonFormField<TruckModel>(
                                              dropdownColor: Colors.white,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                              ),
                                              isExpanded: true,
                                              value: _selectedTruck,
                                              items: _trucks
                                                  .map(
                                                    (truck) =>
                                                        DropdownMenuItem<
                                                          TruckModel
                                                        >(
                                                          value: truck,
                                                          child: Text(
                                                            truck.number ?? "-",
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ),
                                                  )
                                                  .toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedTruck = value;
                                                  nameController.text =
                                                      value?.number ?? "";
                                                });
                                              },
                                              decoration: InputDecoration(
                                                fillColor: Colors.white,
                                                hintText: "Select truck",
                                                hintStyle: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                isDense: true,
                                              ),
                                            ))
                                    else
                                      TextField(
                                        controller: nameController,
                                        decoration: InputDecoration(
                                          fillColor: Colors.white,
                                          hintText: "Enter group name",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusColor: AppColors.primary,
                                          isDense: true,
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Description",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: descriptionController,
                                      maxLines: 3,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        fillColor: Colors.white,
                                        filled: true,
                                        hintText: "What is this group about?",
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.description_outlined,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        alignLabelWithHint: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              Get.context!,
                                            ).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: group.id == null
                                            ? null
                                            : () async {
                                                final newName = nameController
                                                    .text
                                                    .trim();
                                                final newDesc =
                                                    descriptionController.text
                                                        .trim();

                                                final ok = await controller
                                                    .updateCurrentGroup(
                                                      name: newName,
                                                      description: newDesc,
                                                    );

                                                if (ok) {
                                                  if (Get.isRegistered<
                                                    GroupController
                                                  >()) {
                                                    Get.find<GroupController>()
                                                        .refreshData();
                                                  }
                                                  if (Get.isRegistered<
                                                    HomeController
                                                  >()) {
                                                    Get.find<HomeController>()
                                                            .selectedName
                                                            .value =
                                                        newName;
                                                  }

                                                  AppSnackbar.success(
                                                    "Updated Group Successfully.",
                                                  );
                                                } else {
                                                  AppSnackbar.error(
                                                    controller.errorText.value,
                                                  );
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text("Update"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 100),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Active Members",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$activeCount",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Inactive Members",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: Colors.black),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$inactiveCount",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: group.id == null
                                        ? null
                                        : () async {
                                            final ok = await controller
                                                .deleteCurrentGroup();
                                            if (ok) {
                                              if (Get.isRegistered<
                                                GroupController
                                              >()) {
                                                Get.find<GroupController>()
                                                    .refreshData();
                                              }
                                              if (Get.isRegistered<
                                                HomeController
                                              >()) {
                                                final home =
                                                    Get.find<HomeController>();
                                                home.groupId.value = "";
                                                home.selectedName.value = "";
                                              }

                                              Get.back();
                                              AppSnackbar.success(
                                                "Deleted Group Successfully.",
                                              );
                                            } else {
                                              AppSnackbar.error(
                                                controller.errorText.value,
                                              );
                                            }
                                          },

                                    child: const Text("Remove Group"),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 100),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Group Members",
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              TextButton.icon(
                                onPressed: group.id == null
                                    ? null
                                    : () async {
                                        final activeProfileIds = controller
                                            .memmbers
                                            .where((m) => m.status == 'active')
                                            .map(
                                              (m) =>
                                                  m.userProfile?.id ??
                                                  m.userProfileId ??
                                                  '',
                                            )
                                            .where((id) => id.isNotEmpty)
                                            .toList();

                                        final added = await Get.dialog<bool>(
                                          AddMemberDialog(
                                            groupId: group.id!,
                                            initialProfileIds: activeProfileIds,
                                          ),
                                        );
                                        if (added == true) {
                                          controller.loadMessages(
                                            group.id!,
                                            1,
                                            "0",
                                          );
                                        }
                                      },
                                icon: const Icon(
                                  Icons.person_add_alt_1_outlined,
                                ),
                                label: const Text("Add Member"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: members.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Center(
                                      child: Text(
                                        "No members found",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: members.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (_, index) {
                                      final m = members[index];
                                      final profile = m.userProfile;
                                      final isActive = m.status == 'active';
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.primary
                                              .withOpacity(0.1),
                                          child: Text(
                                            (profile?.username ?? "?")
                                                .characters
                                                .take(1)
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        title: Text(profile?.username ?? "-"),
                                        subtitle: Text(
                                          [
                                                profile?.user?.email ?? "",
                                                profile?.user?.phoneNumber ??
                                                    "",
                                              ]
                                              .where((e) => e.isNotEmpty)
                                              .join(" • "),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (isActive
                                                            ? Colors.green
                                                            : Colors.red)
                                                        .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                m.status ?? '-',
                                                style: TextStyle(
                                                  color: isActive
                                                      ? Colors.green[700]
                                                      : Colors.red[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              tooltip: isActive
                                                  ? "Deactivate"
                                                  : "Activate",
                                              icon: Icon(
                                                isActive
                                                    ? Icons.pause_circle_outline
                                                    : Icons.play_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                final newStatus = isActive
                                                    ? 'inactive'
                                                    : 'active';
                                                final res = await GroupService()
                                                    .updateGroupMemberStatus(
                                                      memberId: m.id ?? "",
                                                      status: newStatus,
                                                    );
                                                if (res.status) {
                                                  controller
                                                          .memmbers[index]
                                                          .status =
                                                      newStatus;
                                                  controller.memmbers.refresh();
                                                  AppSnackbar.success(
                                                    "Updated Status Successfully.",
                                                  );
                                                } else {
                                                  AppSnackbar.error(
                                                    controller.errorText.value,
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              tooltip: "Remove from group",
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                final res = await GroupService()
                                                    .removeGroupMember(
                                                      m.id ?? "",
                                                    );
                                                if (res.status) {
                                                  controller.memmbers.removeAt(
                                                    index,
                                                  );
                                                  AppSnackbar.success(
                                                    "Removed Member from group.",
                                                  );
                                                } else {
                                                  AppSnackbar.error(
                                                    res.message,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
