import 'package:chat_app/core/widgets/app_dialog.dart';
import 'package:chat_app/core/widgets/input_field.dart';
import 'package:chat_app/modules/home/controllers/channel_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateChannelDialog extends StatelessWidget {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  CreateChannelDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: "Create Channel",
      submitText: "Create Channel",

      content: Form(
        key: formKey,
        child: Column(
          children: [
            InputField(
              label: "Channel name",
              hint: "e.g. marketing",
              controller: nameController,
              validator: (v) => v == null || v.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 16),

            InputField(
              label: "Description",
              hint: "Optional description",
              controller: descController,
              maxLines: 3,
            ),
          ],
        ),
      ),

      onSubmit: () {
        if (!formKey.currentState!.validate()) return;

        Get.find<ChannelController>().handleChannelCreate(
          nameController.text,
          descController.text,
        );
      },
    );
  }
}
