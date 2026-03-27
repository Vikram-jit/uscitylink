import 'package:chat_app/modules/broadcast_messages/Broadcast_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BroadcastList extends StatelessWidget {
  final controller = Get.find<BroadcastController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Broadcast List",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.broadcasts.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                controller: controller.scrollController,
                itemCount:
                    controller.broadcasts.length +
                    (controller.hasMore.value ? 1 : 0),
                itemBuilder: (_, index) {
                  if (index == controller.broadcasts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = controller.broadcasts[index];

                  final isSent = item.totalMessages == item.sentMessages;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.campaign,
                            color: Color(0xFF4A154B),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${item.totalMessages} total | ${item.sentMessages} sent",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        _statusChip(isSent),

                        const SizedBox(width: 10),

                        Text(
                          _formatDate(item.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),

                        const SizedBox(width: 10),

                        TextButton(
                          onPressed: () {
                            // open detail dialog
                          },
                          child: const Text("Detail"),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isSent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSent
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSent ? "Sent" : "Processing",
        style: TextStyle(
          color: isSent ? Colors.green : Colors.orange,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
