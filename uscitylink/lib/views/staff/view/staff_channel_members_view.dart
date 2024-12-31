import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/drawer_controller.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/model/staff/channel_member_model.dart';
import 'package:uscitylink/model/staff/driver_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class StaffChannelMembersView extends StatelessWidget {
  StaffChannelMembersView({super.key});

  final CustomDrawerController _customDrawerController =
      Get.find<CustomDrawerController>();

  final StaffchannelController _staffChannelController =
      Get.find<StaffchannelController>();

  void _showFullPageBottomSheet(BuildContext context) {
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
                      "Choose Drivers to Add to the Channel",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      height: 40,
                      child: TextField(
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
                            height:
                                40, // Height of the container to match the search bar height
                            child: TextButton(
                              onPressed: () {
                                Get.back();
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors
                                    .transparent, // Transparent background
                                padding: EdgeInsets
                                    .zero, // No padding inside the button
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      5), // Rounded corners
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.redAccent, // Text color
                                  fontSize: 14, // Font size
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            height:
                                30, // Height of the container to match the search bar height
                            child: ElevatedButton(
                              onPressed: () {
                                _showFullPageBottomSheet(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColors.primaryStaff,
                                // Set button color

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                  // Rounded corners
                                ),
                                padding: EdgeInsets
                                    .zero, // No padding inside the button
                              ),
                              child: Text(
                                "submit",
                                style: TextStyle(
                                  color: Colors.white, // Text color
                                  fontSize: 14, // Font size
                                ),
                              ),
                            ),
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
          });
    } else {
      // Handle the case where context is null
      print("Context is not available for the bottom sheet.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final StaffchannelController _staffChannelController =
        Get.find<StaffchannelController>();

    _staffChannelController.getChannelMembers();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120), // Set height for the AppBar
        child: Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
              ),
              backgroundColor: TColors
                  .primaryStaff, // Set your custom color (TColors.primaryStaff)
              title: Text(
                "Channel Members",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Container(
              height: 60.0, // Height for the search bar + button
              color: TColors
                  .primaryStaff, // Set your custom color (TColors.primaryStaff)
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Search bar
                  Expanded(
                    child: Container(
                      height: 40,
                      child: TextField(
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
                  ),
                  SizedBox(
                      width: 10), // Space between the search bar and button
                  // Button next to the search bar
                  Container(
                    height:
                        40, // Height of the container to match the search bar height
                    child: ElevatedButton(
                      onPressed: () {
                        _showFullPageBottomSheet(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        // Set button color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(5), // Rounded corners
                        ),
                        padding:
                            EdgeInsets.zero, // No padding inside the button
                      ),
                      child: Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white, // Text color
                          fontSize: 16, // Font size
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (_staffChannelController.loading.value) {
          return Center(child: CircularProgressIndicator());
        } else if (_staffChannelController.channelMebers.isEmpty) {
          return Center(child: Text('No members found.'));
        } else {
          return ListView.builder(
            itemCount: _staffChannelController.channelMebers.length,
            itemBuilder: (context, index) {
              ChannelMemberModel channel =
                  _staffChannelController.channelMebers[index];
              return Column(
                children: [
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    elevation: 2,
                    child: ListTile(
                      trailing: Icon(Icons.arrow_right),
                      title: Text(
                          "${channel.userProfile?.username} (${channel?.userProfile?.user?.driverNumber})" ??
                              'No Name'),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }),
    );
  }
}
