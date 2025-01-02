import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffchannel_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/staff/drawer/custom_drawer.dart';

class StaffChannelView extends StatefulWidget {
  const StaffChannelView({super.key});

  @override
  State<StaffChannelView> createState() => _StaffChannelViewState();
}

class _StaffChannelViewState extends State<StaffChannelView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final StaffchannelController _channelController =
      Get.find<StaffchannelController>();

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   _channelController.getUserChannels();
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              AppBar(
                leading: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Open the drawer using the scaffold key
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),

                backgroundColor: TColors
                    .primaryStaff, // Uncomment to use your custom primary color
                title: Text(
                  "Channels",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end, // Align icons to the right
                      children: [],
                    ),
                  ),
                ],
              ),
              Container(
                height: 1.0, // Thickness of the line
                color: Colors.grey.shade300, // Color of the line (light grey)
              ),
            ],
          ),
        ),
        body: Obx(() {
          return ListView.builder(
            itemBuilder: (context, index) {
              final channel = _channelController.channels[index];
              return Column(
                children: [
                  ListTile(
                    // Remove the leading icon by not including the `leading` property
                    title: Text('${channel.name}'),
                    trailing: InkWell(
                      onTap: () {
                        _channelController.updateActiveChannel(channel.id!);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: channel.isActive == true
                                ? TColors.primaryStaff
                                : Colors.amber,
                            borderRadius: BorderRadius.circular(5)),
                        width: 70,
                        height: 30,
                        child: Center(
                            child: Text(
                          "${channel.isActive == true ? "selected" : "select"}",
                          style: TextStyle(color: Colors.white),
                        )),
                      ),
                    ),
                  ),
                  Divider()
                ],
              );
            },
            itemCount: _channelController.channels.length,
          );
        }),
        drawer: CustomDrawer());
  }
}
