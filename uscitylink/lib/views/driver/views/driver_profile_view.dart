import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/login_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/driver_pay_view.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

class DriverProfileView extends StatelessWidget {
  DriverProfileView({super.key});
  LoginController _controller = Get.put(LoginController());
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.getDriverProfile();
    });

    return Scaffold(
      backgroundColor: TColors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(210),
        child: Column(
          children: [
            AppBar(
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Open the drawer using the scaffold key
                  Get.back();
                },
              ),
              backgroundColor: TColors.primary,
              // title: Text(
              //   "Profile",
              //   style: Theme.of(context)
              //       .textTheme
              //       .headlineMedium
              //       ?.copyWith(color: Colors.white),
              // ),
            ),
            Container(
              height: 150.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: TColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue
                        .withOpacity(0.2), // Shadow color with opacity
                    spreadRadius: 2, // How much the shadow spreads
                    blurRadius: 10, // Blur effect
                    offset: Offset(0, 5), // Moves shadow downward (x: 0, y: 5)
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      final driver = _controller
                          .driverProfile.value.driver; // Store locally

                      return Text(
                        "${driver?.name} (${driver?.driverNumber})",
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: Colors.white, fontSize: 24),
                      );
                    }),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.mail,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(
                          width: 6,
                        ),
                        Obx(() {
                          return Text(
                            "${_controller.driverProfile?.value.driver?.email}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Colors.white),
                          );
                        })
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(
                          width: 6,
                        ),
                        Obx(() {
                          return Text(
                            "${_controller.driverProfile?.value.driver?.phoneNumber}",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Colors.white),
                          );
                        })
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () {
                            Get.to(() => DriverPayView());
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5)),
                            child: Text(
                              "Pay summary",
                              style: TextStyle(
                                  color: TColors.buttonPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Basic Details",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text.rich(
                                TextSpan(
                                  text: "Address:",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                  children: [
                                    TextSpan(
                                        text: "N/A",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400))
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text.rich(
                                TextSpan(
                                  text: "License Number:",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                  children: [
                                    TextSpan(
                                        text: "N/A",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400))
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text.rich(
                                TextSpan(
                                  text: "city:",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                  children: [
                                    TextSpan(
                                        text: "N/A",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400))
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text.rich(
                                TextSpan(
                                  text: "Issue Date:",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                  children: [
                                    TextSpan(
                                        text: "N/A",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400))
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "state:",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                  children: [
                                    TextSpan(
                                        text: "N/A",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400))
                                  ],
                                ),
                              ),
                              flex: 1,
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "Expiry Date:",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                  children: [
                                    TextSpan(
                                        text: "N/A",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400))
                                  ],
                                ),
                              ),
                              flex: 1,
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "zip code:",
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                  children: [
                                    TextSpan(
                                        text: "N/A",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w400))
                                  ],
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Documents",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Obx(() {
                          final documents =
                              _controller.driverProfile.value.document ?? [];
                          if (documents.length == 0) {
                            return Center(child: Text("No Document Found"));
                          }
                          return Column(
                            children: documents.map((doc) {
                              return ExpansionTile(
                                collapsedShape: Border.all(
                                    color: Colors.transparent,
                                    style: BorderStyle.none),
                                title: Text(doc.title ?? "Unknown Document"),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16.0, right: 16.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_month,
                                                        size: 14),
                                                    Text(
                                                      "Issue Date",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                              fontSize: 16),
                                                    ),
                                                  ],
                                                ),
                                                Text(doc.issueDate ?? "N/A",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700))
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_month,
                                                        size: 14),
                                                    Text(
                                                      "Expire Date",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                              fontSize: 16),
                                                    ),
                                                  ],
                                                ),
                                                Text(doc.expireDate ?? "N/A",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700))
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.document_scanner,
                                                        size: 16),
                                                    Text(
                                                      "Document",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                              fontSize: 16),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 6),
                                                if (doc.file != null)
                                                  InkWell(
                                                    onTap: () {
                                                      Get.to(() =>
                                                          DocumentDownload(
                                                            file:
                                                                "https://msyard.s3.us-west-1.amazonaws.com/images/${doc.file}",
                                                          ));
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8),
                                                      decoration: BoxDecoration(
                                                          color: Colors.amber,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5)),
                                                      child: Center(
                                                        child: Text(
                                                          "view",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              );
                            }).toList(), // ✅ Convert map() to a list
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Country Status",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: TColors.primary,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Obx(() {
                                return Text(
                                  "${_controller.driverProfile.value.countryStatus?.country_status != null ? _controller.driverProfile.value.countryStatus?.country_status : "pending"}",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800),
                                );
                              })),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      if (_controller.driverProfile.value.countryStatus
                              ?.country_status ==
                          "workpermit")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month, size: 14),
                                    Text(
                                      "Issue Date",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Text(
                                    _controller.driverProfile.value
                                            .countryStatus?.issue_date ??
                                        "N/A",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700))
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month, size: 14),
                                    Text(
                                      "Expire Date",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontSize: 16),
                                    ),
                                  ],
                                ),
                                Text(
                                    _controller.driverProfile.value
                                            .countryStatus?.expiry_date ??
                                        "N/A",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700))
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.document_scanner, size: 16),
                                    Text(
                                      "Document",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontSize: 16),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                if (_controller.driverProfile.value
                                        .countryStatus?.document !=
                                    null)
                                  InkWell(
                                    onTap: () {
                                      Get.to(() => DocumentDownload(
                                            file:
                                                "https://msyard.s3.us-west-1.amazonaws.com/images/${_controller.driverProfile.value.countryStatus?.document}",
                                          ));
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Center(
                                        child: Text(
                                          "view",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
