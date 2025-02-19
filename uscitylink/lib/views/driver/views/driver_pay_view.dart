import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/pay_controller.dart';
import 'package:uscitylink/controller/staff/staffdriver_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/document_view.dart';
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
        return ListView.builder(
          controller: ScrollController()
            ..addListener(() {
              // Don't load more if data is already loading
              if (_payController.isLoading.value) return;

              // Check if there are more pages and trigger data fetch if necessary
              if (_payController.currentPage.value <
                  _payController.totalPages.value) {
                if (_payController.pays.isNotEmpty &&
                    _payController.pays.last ==
                        _payController.pays[_payController.pays.length - 1]) {
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
                      color: Colors.transparent, style: BorderStyle.none),
                  title: Text("${pay.tripId}"),

                  /// subtitle: Divider(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        ?.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                              Text("${pay.startDate}")
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        ?.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                              Text("${pay.endDate}")
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.money,
                                    size: 14,
                                  ),
                                  Text(
                                    "Amount",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                              Text("${pay.amount}")
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (pay.document != null)
                      Padding(
                        padding: EdgeInsets.only(top: 10, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () {
                                Get.to(() => DocumentDownload(
                                      file:
                                          "https://msyard.s3.us-west-1.amazonaws.com/images/${pay.document}",
                                    ));
                              },
                              child: Container(
                                margin: EdgeInsets.only(left: 10),
                                padding: EdgeInsets.all(6),
                                height: 30,
                                decoration: BoxDecoration(
                                    color: TColors.primaryStaff,
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  "View Document",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                ),
                Divider()
              ],
            );
          },
        );
      }),
    );
  }
}
