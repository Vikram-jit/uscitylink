import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/staff/staffdriver_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class StaffDriverView extends StatelessWidget {
  StaffDriverView({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StaffDriverController _staffDriverController =
      Get.put(StaffDriverController());
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staffDriverController
          .getDriver(_staffDriverController.currentPage.value);
    });
    return Scaffold(
      key: _scaffoldKey,
      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: Colors.amber,
      //   onPressed: () {},
      //   label: Row(
      //     children: [
      //       Padding(
      //         padding: const EdgeInsets.only(right: 4.0),
      //         child: Icon(
      //           Icons.add,
      //           color: Colors.white,
      //         ),
      //       ),
      //       Text("Add Driver", style: TextStyle(color: Colors.white))
      //     ],
      //   ),
      // ),
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
                "Drivers",
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
                  // ElevatedButton(
                  //   onPressed: () {},
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.amber,
                  //     shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(5)),
                  //     padding: EdgeInsets.zero,
                  //   ),
                  //   child: Text(
                  //     "Add",
                  //     style: TextStyle(color: Colors.white, fontSize: 16),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        return ListView.builder(
          controller: ScrollController()
            ..addListener(() {
              // Don't load more if data is already loading
              if (_staffDriverController.loading.value) return;

              // Check if there are more pages and trigger data fetch if necessary
              if (_staffDriverController.currentPage.value <
                  _staffDriverController.totalPages.value) {
                if (_staffDriverController.drivers.isNotEmpty &&
                    _staffDriverController.drivers.last ==
                        _staffDriverController.drivers[
                            _staffDriverController.drivers.length - 1]) {
                  _staffDriverController
                      .getDriver(_staffDriverController.currentPage.value + 1);
                }
              }
            }),
          itemCount: _staffDriverController.drivers?.length,
          itemBuilder: (context, index) {
            var driver = _staffDriverController.drivers?[index];
            return ExpansionTile(
              // leading: GetBuilder<StaffDriverController>(
              //   builder: (controller) {
              //     return Stack(
              //       clipBehavior: Clip.none,
              //       children: [
              //         CircleAvatar(
              //           radius: 25,
              //           backgroundColor: Colors.grey.shade400,
              //           child: Text(
              //             driver?.username?.substring(0, 1).toUpperCase() ??
              //                 '', // Show first letter of username
              //             style: const TextStyle(
              //               color: Colors.black,
              //               fontSize: 18,
              //             ),
              //           ),
              //         ),

              //         // Online Badge in the top-right corner, wrapped in Obx
              //         if (driver?.isOnline ??
              //             false) // Show badge if user is online
              //           Positioned(
              //             right: 0,
              //             bottom: 0,
              //             child: Container(
              //               width: 10,
              //               height: 10,
              //               decoration: BoxDecoration(
              //                 color: Colors
              //                     .green, // Green color for online status
              //                 shape: BoxShape.circle,
              //                 border: Border.all(
              //                   color: Colors
              //                       .white, // White border around the badge
              //                   width: 2,
              //                 ),
              //               ),
              //             ),
              //           ),
              //       ],
              //     );
              //   },
              //),
              title:
                  Text("${driver?.username} (${driver?.user?.driverNumber})"),

              /// subtitle: Divider(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Email",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text("${driver?.user?.email}")
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Phone Number",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text("${driver?.user?.phoneNumber}")
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Status",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Badge(
                            backgroundColor: driver?.status == "active"
                                ? Colors.green
                                : Colors.redAccent,
                            label: Text(
                              "active",
                              style: TextStyle(fontSize: 14),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      child: Container(
                        margin: EdgeInsets.only(left: 10),
                        padding: EdgeInsets.all(6),
                        height: 30,
                        decoration: BoxDecoration(
                            color: TColors.primaryStaff,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          "Generate New Password",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    )
                  ],
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
