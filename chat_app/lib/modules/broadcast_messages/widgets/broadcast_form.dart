import 'package:chat_app/modules/broadcast_messages/broadcast_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BroadcastForm extends StatelessWidget {
  final controller = Get.put(BroadcastFormController());

  BroadcastForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Broadcast Message",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _modeButton("Specific", "specific"),
                _modeButton("All", "all"),
              ],
            ),

            const SizedBox(height: 16),

            // ================= USER SECTION =================
            if (controller.mode.value == "specific") ...[
              TextField(
                style: TextStyle(color: Colors.black),
                onChanged: controller.setSearch,
                decoration: InputDecoration(
                  hintText: "Search drivers...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🔥 IMPORTANT FIX
              Flexible(
                child: Obx(() {
                  if (controller.isLoading.value && controller.users.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    controller: controller.scrollController,
                    itemCount:
                        controller.users.length +
                        (controller.hasMore.value ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == controller.users.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final user = controller.users[i];
                      final selected = controller.selectedUsers.contains(user);

                      return ListTile(
                        dense: true,
                        title: Text(user.userProfile?.username ?? ""),
                        subtitle: Text(
                          user.userProfile?.user?.driverNumber ?? "",
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Checkbox(
                          value: selected,
                          onChanged: (_) => controller.toggleUser(user),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],

            const SizedBox(height: 10),

            // ================= CHIPS =================
            if (controller.isAllSelected.value)
              const Chip(label: Text("All Users Selected"))
            else if (controller.selectedUsers.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: controller.selectedUsers.map((u) {
                  return Chip(
                    label: Text(u.userProfile?.username ?? ""),
                    onDeleted: () => controller.toggleUser(u),
                  );
                }).toList(),
              ),

            const SizedBox(height: 10),

            // ================= MESSAGE =================
            TextField(
              style: TextStyle(color: Colors.black),
              controller: controller.messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter message...",
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: controller.pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text("Attach"),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A154B),
                ),
                child: const Text("Send Message"),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _modeButton(String label, String value) {
    final controller = Get.find<BroadcastFormController>();

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeMode(value),
        child: Obx(() {
          final isSelected = controller.mode.value == value;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A154B).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4A154B)
                    : Colors.grey.shade300,
              ),
            ),
            child: Center(child: Text(label)),
          );
        }),
      ),
    );
  }
}
