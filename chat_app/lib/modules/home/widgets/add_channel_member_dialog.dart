import 'package:chat_app/core/widgets/app_dialog.dart';
import 'package:chat_app/core/widgets/auto_complete_input_field.dart';
import 'package:chat_app/core/widgets/multi_select_auto_complete_field.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:chat_app/modules/home/models/user_profile_model.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddChannelMemberDialog extends StatefulWidget {
  const AddChannelMemberDialog({super.key});

  @override
  State<AddChannelMemberDialog> createState() => _AddChannelMemberDialogState();
}

class _AddChannelMemberDialogState extends State<AddChannelMemberDialog> {
  final formKey = GlobalKey<FormState>();

  final ChannelController _controller = Get.find<ChannelController>();

  @override
  void initState() {
    super.initState();

    /// ✅ CALL ONLY ONCE
    if (_controller.drivers.isEmpty) {
      _controller.getDriverss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: "Add Channel Members",
      submitText: "Add",

      content: Form(
        key: formKey,
        child: Obx(() {
          /// 🔄 LOADER
          if (_controller.isLoadingDrivers.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              MultiSelectAutoCompleteField<UserProfileModel>(
                label: "Select Drivers",
                hint: "Search drivers...",

                items: _controller.drivers,

                displayText: (user) =>
                    "${user.username} (${user.user?.driverNumber})",

                selectedItems: _controller.selectedDrivers,

                onChanged: (list) {
                  _controller.selectedDrivers.assignAll(list);
                },
              ),
              // AutoCompleteInputField<UserProfileModel>(
              //   label: "Select Driver",
              //   hint: "Search driver...",

              //   /// ✅ REACTIVE DATA
              //   items: _controller.drivers.toList(),

              //   displayText: (user) =>
              //       "${user.username} (${user.user?.driverNumber})",

              //   onSelected: (user) {
              //     _controller.selectedDriver.value = user;
              //   },
              // ),
            ],
          );
        }),
      ),

      onSubmit: () {
        if (!formKey.currentState!.validate()) return;

        /// 👉 CALL API
        _controller.handleDriverAddToChannel();

        Get.back();
      },
    );
  }
}
