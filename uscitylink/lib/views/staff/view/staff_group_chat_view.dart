import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/staff/staffgroup_controller.dart';
import 'package:uscitylink/model/group_model.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/theme/app_text.dart';
import 'package:uscitylink/utils/theme/app_tokens.dart';
import 'package:uscitylink/views/staff/widgets/staff_ui.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';
import 'package:uscitylink/views/staff/widgets/group_tab.dart';
import 'package:uscitylink/views/staff/widgets/truck_group_tab.dart';

class StaffGroupChatView extends StatefulWidget {
  const StaffGroupChatView({super.key});

  @override
  State<StaffGroupChatView> createState() => _StaffGroupChatViewState();
}

class _StaffGroupChatViewState extends State<StaffGroupChatView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  // Assuming you have a controller to manage unread counts (this will be used in Obx)
  final StaffgroupController _staffGroupController =
      Get.put(StaffgroupController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SocketService socketService = Get.find<SocketService>();
  @override
  void initState() {
    super.initState();
    _staffGroupController.getTrucks();
    // Initializing the tab controller with 2 tabs (Channels & Groups)
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes if needed
    _tabController.addListener(() {
      _staffGroupController.groups.value.data?.clear();
      _staffGroupController.groups.refresh();
      _staffGroupController.update();
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _staffGroupController.type.value = "group";
        _staffGroupController.getGroups(_staffGroupController.currentPage.value,
            _staffGroupController.searchController.text);
        _staffGroupController.searchController.text = "";
      }
      if (_tabController.index == 0 && !_tabController.indexIsChanging) {
        _staffGroupController.type.value = "truck";
        _staffGroupController.getGroups(_staffGroupController.currentPage.value,
            _staffGroupController.searchController.text);
        _staffGroupController.searchController.text = "";
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      // Add logic for when the app goes to the background
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      Timer(Duration(seconds: 2), () {
        socketService.checkVersion();
      });
      // Add logic for when the app comes back to the foreground
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _staffGroupController.getTrucks();
    return AnnotatedRegion(
      value: kStaffOverlay,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: StaffColors.canvas,
        drawer: CustomDrawer(),
        floatingActionButton: Obx(() {
          final isGroup = _staffGroupController.type.value == "group";
          return StaffFab(
            heroTag: "kjdld",
            label: isGroup ? "New group" : "New truck group",
            icon: Icons.add_rounded,
            onPressed: () => _showGroupNameDialog(_staffGroupController.type.value),
          );
        }),
        body: Column(
          children: [
            StaffHeader(
              title: "Group chats",
              subtitle: "Truck groups and team groups",
              onLeading: () => _scaffoldKey.currentState?.openDrawer(),
              bottom: Column(
                children: [
                  StaffSearchField(
                    controller: _staffGroupController.searchController,
                    onChanged: _staffGroupController.onSearchChanged,
                    hint: "Search groups…",
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StaffSegmentedTabs(controller: _tabController, labels: const ['Truck groups', 'Groups']),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  TruckGroupTab(),
                  GroupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New group / truck group
  void _showGroupNameDialog(String type) {
    final isGroup = type == "group";
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: StaffColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(isGroup ? Icons.groups_rounded : Icons.local_shipping_rounded, color: StaffColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      isGroup ? 'New group' : 'New truck group',
                      style: AppText.titleLg.copyWith(color: StaffColors.textStrong),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded, color: StaffColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              if (isGroup)
                TextField(
                  controller: _staffGroupController.groupName,
                  autofocus: true,
                  decoration: _fieldDecoration('Group name'),
                ),
              if (!isGroup)
                Obx(
                  () => DropdownButtonFormField<String>(
                    dropdownColor: Colors.white,
                    isExpanded: true,
                    value: _staffGroupController.selectedTruck.value.isEmpty
                        ? null
                        : _staffGroupController.selectedTruck.value,
                    decoration: _fieldDecoration('Truck number'),
                    hint: const Text('Select a truck'),
                    onChanged: (String? newValue) {
                      _staffGroupController.selectedTruck.value = newValue ?? "";
                    },
                    items: _staffGroupController.trucks
                        .map<DropdownMenuItem<String>>(
                          (value) => DropdownMenuItem<String>(
                            value: value.number,
                            child: Text("${value.number}", style: AppText.bodyLg),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StaffColors.textBody,
                        side: const BorderSide(color: StaffColors.hairline, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _staffGroupController.addGroup(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StaffColors.primary,
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      ),
                      child: Text(isGroup ? 'Create group' : 'Create truck group'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: StaffColors.canvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: StaffColors.primary, width: 1.5),
        ),
      );
}
