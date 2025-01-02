// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/model/staff/channel_member_model.dart';
import 'package:uscitylink/views/staff/widgets/driver_dialog.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class StaffChannelMembersView extends StatelessWidget {
  StaffChannelMembersView({super.key});

  // Get the controller for staff channel
  final StaffchannelController _staffChannelController =
      Get.find<StaffchannelController>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staffChannelController.getDrivers();
      _staffChannelController.getChannelMembers();
    });

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // Navigate back
                },
              ),
              backgroundColor: TColors.primaryStaff,
              title: Text(
                "Channel Members",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Container(
              height: 60.0,
              color: TColors.primaryStaff,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
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
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      DriverDialog.showDriverBottomSheet(
                          context, _staffChannelController);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Add",
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
              return Slidable(
                  key: Key(channel.userProfile?.username ?? 'Unknown'),
                  direction: Axis.horizontal, // Allow horizontal sliding

                  child: Card(
                    margin: EdgeInsets.all(1),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0)),
                    elevation: 1,
                    child: ListTile(
                      trailing: Icon(
                        Icons.circle,
                        color: channel.userProfile?.isOnline == true
                            ? Colors.green
                            : Colors.grey,
                        size: 14,
                      ),
                      title: Text(
                        "${channel.userProfile?.username} (${channel.userProfile?.user?.driverNumber ?? 'No Number'})",
                      ),
                    ),
                  ),
                  endActionPane: ActionPane(
                      extentRatio: 0.7,
                      motion: const ScrollMotion(),
                      children: [
                        Expanded(
                          child: Container(
                            child: Icon(
                              Icons.settings,
                              size: 32,
                              color: Colors.black,
                            ),
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.red,
                            ),
                            child: Icon(
                              Icons.delete,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ]));
            },
          );
        }
      }),
    );
  }
}
