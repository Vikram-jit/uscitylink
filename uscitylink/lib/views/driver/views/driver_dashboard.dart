import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/services/socket_service.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/driver/widegts/stat_card.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with WidgetsBindingObserver {
  SocketService socketService = Get.find<SocketService>();
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes (background/foreground)
    if (state == AppLifecycleState.paused) {
      if (socketService.isConnected.value) {
        socketService.socket.disconnect();
      }
      print("App is in the background");
    } else if (state == AppLifecycleState.resumed) {
      if (!socketService.isConnected.value) {
        socketService.connectSocket();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              backgroundColor:
                  TColors.primary, // Uncomment to use your custom primary color
              title: Text(
                "Dashboard",
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
                    children: [
                      // Profile Image Container
                      // Container(
                      //   height: 35,
                      //   width: 35,
                      //   child: ClipRRect(
                      //     borderRadius: BorderRadius.circular(6),
                      //     child: Image.asset(
                      //       "assets/images/placeholder.png", // Path to your image asset
                      //       fit: BoxFit.cover,
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(width: 10),

                      Center(
                        child: Icon(
                          Icons.notification_add,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Add a bottom line under the AppBar using a Container
            Container(
              height: 1.0, // Thickness of the line
              color: Colors.grey.shade300, // Color of the line (light grey)
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            children: [
              //Announcement Ui
              // SizedBox(
              //   height: TDeviceUtils.getAppBarHeight() * 0.2,
              // ),
              // Card(
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(5.0),
              //   ),
              //   color: Color(0XFF272727).withOpacity(1),
              //   elevation: 0.0,
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       SizedBox(
              //         height: TDeviceUtils.getAppBarHeight() * 0.2,
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.symmetric(horizontal: 8),
              //         child: Row(
              //           children: [
              //             Text(
              //               'Important Announcement',
              //               style: Theme.of(context)
              //                   .textTheme
              //                   .titleLarge
              //                   ?.copyWith(color: Colors.white),
              //             ),
              //             SizedBox(
              //               width: TDeviceUtils.getAppBarHeight() * 0.2,
              //             ),
              //             const Icon(
              //               Icons.announcement,
              //               color: Colors.yellowAccent,
              //             )
              //           ],
              //         ),
              //       ),
              //       SizedBox(
              //         height: TDeviceUtils.getAppBarHeight() * 0.1,
              //       ),
              //       Padding(
              //         padding: const EdgeInsets.only(
              //             left: 8.0, right: 8.0, bottom: 8.0),
              //         child: Text(
              //           'This is the body of the card. You can put any content here, .',
              //           style: Theme.of(context)
              //               .textTheme
              //               .bodySmall
              //               ?.copyWith(color: Colors.white),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              //Announcement Ui End
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 0.3,
              ),
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 1.2,
                child: const Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: "TOTAL CHANNEL",
                        value: 18,
                        icon: Icons.wifi_channel,
                        gradientColors: [
                          Color(
                              0xFFe5e5e5), // Hex color for a shade of green (Active User)
                          Color(0xFFe5e5e5),
                        ], // Gradient colors
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: "TOTAL MESSAGE",
                        icon: Icons.message,
                        value: 18,
                        gradientColors: [
                          Color(
                              0xFFe5e5e5), // Hex color for a shade of green (Active User)
                          Color(0xFFe5e5e5),
                        ], // Gradient colors
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 0.1,
              ),
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 1.2,
                child: const Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.fire_truck,
                        title: "TRUCKS",
                        value: 18,
                        gradientColors: [
                          Color(
                              0xFFe5e5e5), // Hex color for a shade of green (Active User)
                          Color(0xFFe5e5e5),
                        ], // Gradient colors
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: "TRAILERS",
                        value: 18,
                        icon: Icons.car_crash,
                        gradientColors: [
                          Color(
                              0xFFe5e5e5), // Hex color for a shade of green (Active User)
                          Color(0xFFe5e5e5),
                        ], // Gradient colors
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 0.30,
              ),
              Row(
                children: [
                  Text("Latest Message",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: TColors.darkGrey))
                ],
              ),
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Channel 1',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.2,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, bottom: 8.0),
                      child: Text(
                        'This is the body of the card. You can put any content here, such as text, images, or even other widgets.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 0.30,
              ),
              Row(
                children: [
                  Text("Group Message",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: TColors.darkGrey))
                ],
              ),
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Test Group',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.2,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, bottom: 8.0),
                      child: Text(
                        'This is the body of the card. You can put any content here, such as text, images, or even other widgets.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
