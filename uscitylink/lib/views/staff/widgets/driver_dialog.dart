import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/model/staff/driver_model.dart';

class DriverDialog {
  // This is the public method to open the bottom sheet
  static void showDriverBottomSheet(
      BuildContext context, StaffchannelController _staffChannelController) {
    _showFullPageBottomSheet(context, _staffChannelController);
  }

  // Private method that displays the full page bottom sheet
  static void _showFullPageBottomSheet(
      BuildContext context, StaffchannelController _staffChannelController) {
    // Ensure you're in the right context
    if (context != null) {
      _staffChannelController.getDrivers();

      showModalBottomSheet(
        showDragHandle: false,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Choose Drivers to Add/Remove to the Channel",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 40,
                    child: TextField(
                      onChanged: (query) {
                        _staffChannelController.searchDrivers(query);
                      },
                      decoration: InputDecoration(
                        hintText: "Search drivers...",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.all(0),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Expanded(
                    child: Obx(
                      () {
                        return ListView.builder(
                          itemBuilder: (context, index) {
                            DriverModel driver =
                                _staffChannelController.drivers[index];
                            if (_staffChannelController.drivers.length == 0) {
                              return Center(
                                child: Text("No Driver Found"),
                              );
                            }
                            return Column(
                              children: [
                                SizedBox(
                                  height: 25,
                                  child: Row(
                                    children: [
                                      Checkbox(
                                          value: driver.isChannelExist,
                                          onChanged: (onChanged) {
                                            _staffChannelController
                                                .addMemberIntoChannel(
                                                    driver.id!, onChanged!);
                                          }),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Flexible(
                                        child: Text(
                                            "${driver.profiles?[0]?.username} (${driver.driverNumber})"),
                                      )
                                    ],
                                  ),
                                ),
                                Divider()
                              ],
                            );
                          },
                          itemCount: _staffChannelController.drivers.length,
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 40,
                          child: TextButton(
                            onPressed: () {
                              Get.back();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(
                              "Close",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
          );
        },
      );
    } else {
      print("Context is not available for the bottom sheet.");
    }
  }

  static void showDriverGroupBottomSheet(BuildContext context,
      StaffchannelController _staffChannelController, String groupId) {
    _showFullPageBottomSheetGroup(context, _staffChannelController, groupId);
  }

  // Private method that displays the full page bottom sheet
  static void _showFullPageBottomSheetGroup(BuildContext context,
      StaffchannelController _staffChannelController, String groupId) {
    // Ensure you're in the right context
    if (context != null) {
      _staffChannelController.getGroupDrivers(groupId);

      showModalBottomSheet(
        showDragHandle: false,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    "Choose Drivers to Add/Remove to the Group",
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 40,
                    child: TextField(
                      onChanged: (query) {
                        _staffChannelController.searchDrivers(query);
                      },
                      decoration: InputDecoration(
                        hintText: "Search drivers...",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.all(0),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Expanded(
                    child: Obx(
                      () {
                        return ListView.builder(
                          itemBuilder: (context, index) {
                            DriverModel driver =
                                _staffChannelController.drivers[index];
                            if (_staffChannelController.drivers.length == 0) {
                              return Center(
                                child: Text("No Driver Found"),
                              );
                            }
                            return Column(
                              children: [
                                SizedBox(
                                  height: 25,
                                  child: Row(
                                    children: [
                                      Checkbox(
                                          value: driver.isChannelExist,
                                          onChanged: (onChanged) {
                                            _staffChannelController
                                                .addMemberIntoGroup(driver.id!,
                                                    onChanged!, groupId);
                                          }),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Flexible(
                                        child: Text(
                                            "${driver.profiles?[0]?.username} (${driver.driverNumber})"),
                                      )
                                    ],
                                  ),
                                ),
                                Divider()
                              ],
                            );
                          },
                          itemCount: _staffChannelController.drivers.length,
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 40,
                          child: TextButton(
                            onPressed: () {
                              Get.back();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(
                              "Close",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  )
                ],
              ),
            ),
          );
        },
      );
    } else {
      print("Context is not available for the bottom sheet.");
    }
  }
}
