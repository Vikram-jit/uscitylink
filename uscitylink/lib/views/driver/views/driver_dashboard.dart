import 'package:flutter/material.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/driver/widegts/stat_card.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        child: Text("A"),
                      ),
                      SizedBox(
                        width: TDeviceUtils.getScreenHeight() * 0.01,
                      ),
                      const Text("Hello,"),
                      SizedBox(
                        width: TDeviceUtils.getScreenHeight() * 0.004,
                      ),
                      const Text(
                        "Text User",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Icon(Icons.notification_add)
                ],
              ),
              //Announcement Ui
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 0.2,
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
                color: Colors.black,
                elevation: 0.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.2,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Text(
                            'Important Announcement',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          SizedBox(
                            width: TDeviceUtils.getAppBarHeight() * 0.2,
                          ),
                          const Icon(
                            Icons.announcement,
                            color: Colors.white,
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: TDeviceUtils.getAppBarHeight() * 0.1,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, bottom: 8.0),
                      child: Text(
                        'This is the body of the card. You can put any content here, .',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              //Announcement Ui End
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 0.3,
              ),
              SizedBox(
                height: TDeviceUtils.getAppBarHeight() * 2,
                child: const Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: "Total Channels",
                        value: 18,
                        gradientColors: [
                          Color(
                              0xFFffde59), // Hex color for a shade of green (Active User)
                          Color(0xFFe45d0d),
                        ], // Gradient colors
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: "Total Message",
                        value: 18,
                        gradientColors: [
                          Color(
                              0xFFff7171), // Hex color for a shade of green (Active User)
                          Color(0xFF9B2020),
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
                height: TDeviceUtils.getAppBarHeight() * 2,
                child: const Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: "Trucks",
                        value: 18,
                        gradientColors: [
                          Color(
                              0xFF9ccd2a), // Hex color for a shade of green (Active User)
                          Color(0xFFffff33),
                        ], // Gradient colors
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: "Trailers",
                        value: 18,
                        gradientColors: [
                          Color(
                              0xFFbff870), // Hex color for a shade of green (Active User)
                          Color(0xFF34ffaa),
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
