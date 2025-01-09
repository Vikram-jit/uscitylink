// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/group_controller.dart';
import 'package:uscitylink/routes/app_routes.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/driver/views/group/member_search.dart';

class StaffGroupDetail extends StatefulWidget {
  String groupId = "";
  StaffGroupDetail({super.key, required this.groupId});

  @override
  State<StaffGroupDetail> createState() => _StaffGroupDetailState();
}

class _StaffGroupDetailState extends State<StaffGroupDetail> {
  GroupController groupController = Get.put(GroupController());
  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      groupController.getGroupById(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: TColors.primaryStaff,
          title: Obx(() {
            return Text(
              "${groupController.group.value.group?.name}",
              style: TextStyle(color: Colors.white),
            );
          }),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            Container(
              height:
                  40, // Height of the container to match the search bar height
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  // Set button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // Rounded corners
                  ),
                  padding: EdgeInsets.zero, // No padding inside the button
                ),
                child: Text(
                  "Add Member",
                  style: TextStyle(
                    color: Colors.white, // Text color
                    fontSize: 16, // Font size
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (groupController.loading.value) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.02,
              ),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  child: CircleAvatar(
                    child: Text(
                      "${groupController.group?.value?.group?.name?[0]}",
                      style: TextStyle(fontSize: 24, color: Colors.black),
                    ),
                    backgroundColor: Colors.grey.shade400,
                  ),
                ),
              ),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.01,
              ),
              Center(
                  child: Text(
                "${groupController.group?.value?.group?.name}",
                style: Theme.of(context).textTheme.headlineMedium,
              )),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.001,
              ),
              Center(
                child: Text(
                  "Group ${groupController?.group?.value?.groupMembers?.length ?? 0} members",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.grey.shade500),
                ),
              ),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.02,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ListTile(
                    onTap: () {
                      Get.toNamed(
                        AppRoutes.groupMedia,
                        arguments: {
                          'groupId': groupController?.group.value?.group?.id
                        },
                      );
                    },
                    minTileHeight: 20,
                    leading: Icon(Icons.photo),
                    title: Text(
                      "Media,docs",
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    trailing: Icon(Icons.arrow_right),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 32.0),
                    child: SizedBox(
                      width: TDeviceUtils.getScreenWidth(context) * 0.75,
                      child: Divider(
                        color: Colors.grey.shade300,
                        height: 0,
                      ),
                    ),
                  ),
                  ListTile(
                    minTileHeight: 20,
                    leading: Icon(Icons.star),
                    title: Text("Pin Messages",
                        style: Theme.of(context).textTheme.labelSmall),
                    trailing: Icon(Icons.arrow_right_outlined),
                  ),
                ],
              ),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.02,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    "${groupController?.group?.value?.groupMembers?.length ?? 0} members",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                  InkWell(
                    onTap: () {
                      Get.bottomSheet(
                          MemberSearch(
                            groupId: widget.groupId,
                            groupMembers:
                                groupController?.group?.value?.groupMembers ??
                                    [],
                          ),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          barrierColor: Colors.black.withOpacity(0.3),
                          enableDrag:
                              true, // Keep the drag functionality active
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(5)),
                          ),
                          clipBehavior: Clip.none);
                    },
                    child: Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
              SizedBox(
                height: TDeviceUtils.getScreenHeight() * 0.02,
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount:
                    groupController?.group?.value?.groupMembers?.length ?? 0,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 5),
                        leading: CircleAvatar(
                          child: Text(
                            "${groupController?.group?.value?.groupMembers?[index]?.userProfile?.username?[0]}",
                            style: TextStyle(color: Colors.black),
                          ),
                          backgroundColor: Colors.grey.shade400,
                        ),
                        title: Text(
                            "${groupController?.group?.value?.groupMembers?[index]?.userProfile?.username}"),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: SizedBox(
                          width: TDeviceUtils.getScreenWidth(context) * 0.75,
                          child: Divider(
                            color: Colors.grey.shade300,
                            height: 0,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            ],
          );
        }));
  }
}
