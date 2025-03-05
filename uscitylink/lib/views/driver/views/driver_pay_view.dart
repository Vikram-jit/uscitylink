import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/pay_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

class DriverPayView extends StatelessWidget {
  DriverPayView({super.key});
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PayController _payController = Get.put(PayController());
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _payController.fetchTrucks(page: _payController.currentPage.value);
    });
    return Scaffold(
      key: _scaffoldKey,
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
              backgroundColor: TColors.primary,
              title: Text(
                "Pays",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      _payController.fetchTrucks(page: 1);
                    },
                    icon: Icon(Icons.refresh, color: Colors.white))
              ],
            ),
            Container(
              height: 60.0,
              color: TColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      child: TextField(
                        controller: _payController.searchController,
                        onChanged: _payController.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search trip...",
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
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (_payController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return RefreshIndicator(
          onRefresh: () => _payController.fetchTrucks(page: 1),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: ScrollController()
                    ..addListener(() {
                      // Don't load more if data is already loading
                      if (_payController.isLoading.value) return;

                      // Check if there are more pages and trigger data fetch if necessary
                      if (_payController.currentPage.value <
                          _payController.totalPages.value) {
                        if (_payController.pays.isNotEmpty &&
                            _payController.pays.last ==
                                _payController
                                    .pays[_payController.pays.length - 1]) {
                          _payController.fetchTrucks(
                              page: _payController.currentPage.value + 1);
                        }
                      }
                    }),
                  itemCount: _payController.pays?.length,
                  itemBuilder: (context, index) {
                    var pay = _payController.pays[index];
                    return Column(
                      children: [
                        ExpansionTile(
                          collapsedShape: Border.all(
                              color: Colors.transparent,
                              style: BorderStyle.none),
                          title: Text("${pay.tripId}"),

                          /// subtitle: Divider(),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Trip - ${pay.tripId}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(
                              width: TDeviceUtils.getScreenWidth(context) * 0.9,
                              child: Card(
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_month,
                                                    size: 14,
                                                  ),
                                                  Text(
                                                    "Start Date",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                            fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              Text("${pay.startDate}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700))
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_month,
                                                    size: 14,
                                                  ),
                                                  Text(
                                                    "End Date",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                            fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              Text("${pay.endDate}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700))
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    Divider(),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Mileage",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(fontSize: 14),
                                              ),
                                              Text("${pay.mileage ?? 0.00}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700))
                                            ],
                                          ),
                                          SizedBox(
                                            height: 6,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Pay Rate(cent)",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(fontSize: 14),
                                              ),
                                              Text("${pay.pay_rate ?? 0}.00",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700))
                                            ],
                                          ),
                                          SizedBox(
                                            height: 6,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Layover",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(fontSize: 14),
                                              ),
                                              Text("+${pay.layover ?? 0.00}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.green))
                                            ],
                                          ),
                                          SizedBox(
                                            height: 6,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Adjustment",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(fontSize: 14),
                                              ),
                                              Text(
                                                  "${pay.adjustment_sign ?? ""}${pay.adjustment ?? 0.00}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: pay.adjustment_sign !=
                                                              null
                                                          ? pay.adjustment_sign ==
                                                                  "-"
                                                              ? Colors.red
                                                              : Colors.green
                                                          : Colors.black))
                                            ],
                                          ),
                                          SizedBox(
                                            height: 6,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Other Pay",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(fontSize: 14),
                                              ),
                                              Text("+${pay.other_pay ?? 0.00}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.green))
                                            ],
                                          ),
                                          SizedBox(
                                            height: 6,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Driver Advance",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(fontSize: 14),
                                              ),
                                              Text(
                                                  "-${pay.driver_addv ?? 0.00}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.red))
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 18),
                                              ),
                                              Text("\$${pay.amount}",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 22))
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Padding(
                            //   padding: const EdgeInsets.only(
                            //       left: 16.0, right: 16.0),
                            //   child: Column(
                            //     children: [
                            //       Row(
                            //         mainAxisAlignment:
                            //             MainAxisAlignment.spaceBetween,
                            //         children: [
                            //           Column(
                            //             crossAxisAlignment:
                            //                 CrossAxisAlignment.start,
                            //             children: [
                            //               Row(
                            //                 children: [
                            //                   Icon(
                            //                     Icons.calendar_month,
                            //                     size: 14,
                            //                   ),
                            //                   Text(
                            //                     "Start Date",
                            //                     style: Theme.of(context)
                            //                         .textTheme
                            //                         .titleSmall
                            //                         ?.copyWith(fontSize: 16),
                            //                   ),
                            //                 ],
                            //               ),
                            //               Text("${pay.startDate}",
                            //                   style: TextStyle(
                            //                       fontWeight: FontWeight.w700))
                            //             ],
                            //           ),
                            //           Column(
                            //             crossAxisAlignment:
                            //                 CrossAxisAlignment.start,
                            //             children: [
                            //               Row(
                            //                 children: [
                            //                   Icon(
                            //                     Icons.calendar_month,
                            //                     size: 14,
                            //                   ),
                            //                   Text(
                            //                     "End Date",
                            //                     style: Theme.of(context)
                            //                         .textTheme
                            //                         .titleSmall
                            //                         ?.copyWith(fontSize: 16),
                            //                   ),
                            //                 ],
                            //               ),
                            //               Text("${pay.endDate}",
                            //                   style: TextStyle(
                            //                       fontWeight: FontWeight.w700))
                            //             ],
                            //           ),
                            //           Column(
                            //             crossAxisAlignment:
                            //                 CrossAxisAlignment.start,
                            //             children: [
                            //               Row(
                            //                 children: [
                            //                   Icon(
                            //                     Icons.money,
                            //                     size: 16,
                            //                   ),
                            //                   Text(
                            //                     "Amount",
                            //                     style: Theme.of(context)
                            //                         .textTheme
                            //                         .titleSmall
                            //                         ?.copyWith(fontSize: 16),
                            //                   ),
                            //                 ],
                            //               ),
                            //               Text(
                            //                 "${pay.amount}",
                            //                 style: TextStyle(
                            //                     fontWeight: FontWeight.w700),
                            //               )
                            //             ],
                            //           ),
                            //         ],
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            // if (pay.document != null)
                            //   Padding(
                            //     padding: EdgeInsets.only(top: 10, right: 10),
                            //     child: InkWell(
                            //       onTap: () {
                            //         Get.to(() => DocumentDownload(
                            //               file:
                            //                   "https://msyard.s3.us-west-1.amazonaws.com/images/${pay.document}",
                            //             ));
                            //       },
                            //       child: Container(
                            //         width:
                            //             TDeviceUtils.getScreenWidth(context) *
                            //                 0.9,
                            //         margin: EdgeInsets.only(left: 10),
                            //         padding: EdgeInsets.all(6),
                            //         height: 30,
                            //         decoration: BoxDecoration(
                            //             color: TColors.primaryStaff,
                            //             borderRadius: BorderRadius.circular(6)),
                            //         child: Center(
                            //           child: Text(
                            //             "View Document",
                            //             style: TextStyle(color: Colors.white),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                        Divider()
                      ],
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Shadow color
                      spreadRadius: 1, // How much the shadow spreads
                      blurRadius: 5, // Softness of the shadow
                      offset: Offset(
                          0, -3), // Moves shadow upwards (negative Y-axis)
                    ),
                  ],
                  color: Colors.white, // Ensure background color is set
                ),
                height: 80,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Total Trips:",
                            style: Theme.of(context)
                                ?.textTheme
                                ?.labelSmall
                                ?.copyWith(fontSize: 14),
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text(
                            "${_payController.totalItems}",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "Total Pay:",
                            style: Theme.of(context)
                                ?.textTheme
                                ?.labelSmall
                                ?.copyWith(fontSize: 14),
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text(
                            "\$${_payController.totalAmount}",
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: TColors.primary),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}
