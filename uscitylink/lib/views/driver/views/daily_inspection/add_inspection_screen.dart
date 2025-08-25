import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/inspection_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class AddInspectionScreen extends StatelessWidget {
  const AddInspectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InspectionController controller = Get.put(InspectionController());

    return Scaffold(
      backgroundColor: TColors.white,
      appBar: AppBar(
        backgroundColor: TColors.primary,
        centerTitle: false,
        title: const Text(
          "Truck Inspection",
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Obx(() => controller.isLoading.value
          ? _buildLoadingScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(controller, context),
                  const SizedBox(height: 24),
                  _buildInspectionGrid(controller, "truck"),
                  _buildTrailerDropdown(controller),
                  const SizedBox(height: 16),
                  if (controller.selectedTrailer.isNotEmpty)
                    _buildInspectionTrailerGrid(controller),
                  _buildSubmitButton(controller),
                  const SizedBox(height: 16),
                ],
              ),
            )),
    );
  }

  Widget _buildLoadingScreen() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(TColors.primary),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );

  Widget _buildHeaderCard(
      InspectionController controller, BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              return Text(
                'Truck #${controller.inspection?.value.groupUser?.group?.name}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TColors.primary,
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Carrier: ${controller.carrierName}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              'Odometer Reading: ${controller.inspection?.value?.odometerMiles} miles',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            // Date Row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.inspectionDate.value,
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Inspection Date',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _selectDate(context, controller),
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text("Change"),
                  style: TextButton.styleFrom(
                    foregroundColor: TColors.primary,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailerDropdown(InspectionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Trailer For Inspection",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Obx(() {
            // Get the list of trailers or empty list if null
            final trailers = controller.inspection?.value?.trailers ?? [];

            return DropdownButton<String>(
              dropdownColor: Colors.white,
              value: controller.selectedTrailer.value.isEmpty
                  ? null
                  : controller.selectedTrailer.value,
              isExpanded: true,
              underline: const SizedBox(),
              items: trailers.isEmpty
                  ? [] // Return empty list if no trailers
                  : trailers.map((trailer) {
                      return DropdownMenuItem<String>(
                        value: trailer.id?.toString() ??
                            '', // Convert id to string
                        child: Text(trailer.number ?? 'Unknown'),
                      );
                    }).toList(),
              onChanged: trailers.isEmpty
                  ? null // Disable dropdown if no trailers
                  : (newValue) {
                      controller.selectedTrailer.value = newValue ?? '';
                    },
              hint: const Text('Select Trailer'),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInspectionGrid(InspectionController controller, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Truck Inspection Sheet",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 18)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: controller.inspectionItems.length,
          itemBuilder: (context, index) {
            final item = controller.inspectionItems.keys.elementAt(index);
            final status = controller.inspectionItems[item];
            return _buildInspectionItem(item, status, controller, type);
          },
        ),
      ],
    );
  }

  Widget _buildInspectionTrailerGrid(InspectionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            "Trailer Inspection Sheet For ${controller.inspection.value.trailers?.elementAt(int.parse(controller.selectedTrailer.value)).number}",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 18)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: controller.inspectionTrailerItems.length,
          itemBuilder: (context, index) {
            final item =
                controller.inspectionTrailerItems.keys.elementAt(index);
            final status = controller.inspectionTrailerItems[item];
            return _buildInspectionItem(item, status, controller, "trailer");
          },
        ),
      ],
    );
  }

  Widget _buildInspectionItem(
      String item, bool? status, InspectionController controller, type) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: status == null
          ? Colors.grey[300]!
          : status == true
              ? Colors.green[300]!
              : Colors.red[300]!,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showStatusDialog(item, status, controller, type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: status == null
                      ? Colors.grey[300]
                      : status == true
                          ? Colors.green
                          : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: status == null
                    ? Icon(Icons.circle_outlined,
                        size: 16, color: Colors.grey[600])
                    : Icon(status ? Icons.check : Icons.close,
                        size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusDialog(String item, bool? currentStatus,
      InspectionController controller, String type) {
    Get.dialog(AlertDialog(
      backgroundColor: Colors.white,
      title: Text(item,
          style:
              TextStyle(fontWeight: FontWeight.w600, color: TColors.primary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusOption(
              '✅ OK', true, currentStatus, item, controller, type),
          const SizedBox(height: 12),
          _buildStatusOption(
              '❌ Problem', false, currentStatus, item, controller, type),
          if (currentStatus != null) ...[
            const SizedBox(height: 16),
            _buildClearOption(item, controller),
          ]
        ],
      ),
    ));
  }

  Widget _buildStatusOption(String label, bool status, bool? currentStatus,
      String item, InspectionController controller, String type) {
    final isSelected = currentStatus == status;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (type == "truck") {
            controller.updateInspectionItem(item, status);
          } else {
            controller.updateInspectionTrailerItem(item, status);
          }

          Get.back();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? (status ? Colors.green[50] : Colors.red[50])
              : Colors.white,
          foregroundColor: isSelected
              ? (status ? Colors.green : Colors.red)
              : Colors.black87,
          side: BorderSide(
            color: isSelected
                ? (status ? Colors.green : Colors.red)
                : Colors.grey[300]!,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildClearOption(String item, InspectionController controller) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          controller.updateInspectionItem(item, null);
          Get.back();
        },
        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
        child: const Text("Clear Selection"),
      ),
    );
  }

  Widget _buildSubmitButton(InspectionController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.submitInspection,
        style: ElevatedButton.styleFrom(
          backgroundColor: TColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("Submit Inspection",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, InspectionController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) controller.updateInspectionDate(picked);
  }
}
