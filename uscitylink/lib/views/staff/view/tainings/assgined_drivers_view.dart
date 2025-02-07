import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class AssginedDriversView extends StatelessWidget {
  final String trainingId;
  AssginedDriversView({super.key, required this.trainingId});
  TrainingController _trainingController = Get.find<TrainingController>();
  @override
  Widget build(BuildContext context) {
    _trainingController.fetchAssginedDriver(id: trainingId, page: 1);
    return Scaffold(
      backgroundColor: TColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              centerTitle: false,
              automaticallyImplyLeading: false,
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
              backgroundColor: TColors.primaryStaff,
              title: Text(
                "Assgined Drivers",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Container(
              height: 1.0,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
      body: Obx(() {
        return ListView.builder(
          controller: ScrollController()
            ..addListener(() {
              // Don't load more if data is already loading
              if (_trainingController.loadDrivers.value) return;

              // Check if there are more pages and trigger data fetch if necessary
              if (_trainingController.currentPage.value <
                  _trainingController.totalPages.value) {
                if (_trainingController.assgin_drivers.isNotEmpty &&
                    _trainingController.assgin_drivers.last ==
                        _trainingController.assgin_drivers[
                            _trainingController.assgin_drivers.length - 1]) {
                  _trainingController.fetchAssginedDriver(
                      id: trainingId,
                      page: _trainingController.currentPage.value + 1);
                }
              }
            }),
          itemCount: _trainingController.assgin_drivers.length,
          itemBuilder: (context, index) {
            var driver = _trainingController.assgin_drivers[index];
            return ExpansionTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "${driver?.userProfiles?.username} (${driver?.userProfiles?.user?.driverNumber})"),
                  if (driver.quizStatus != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Badge(
                        backgroundColor: driver.quizStatus == "passed"
                            ? Colors.green
                            : driver.quizStatus == "failed"
                                ? Colors.red
                                : Colors.grey,
                        label: Text(
                          driver.quizStatus == "passed"
                              ? "Certified"
                              : driver.quizStatus ?? "-",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    )
                ],
              ),

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
                            "View Durations",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text("${driver?.viewDuration}")
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "View Status",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Badge(
                            backgroundColor: driver.viewDuration != null
                                ? (driver.isCompleteWatch!
                                    ? Colors.green
                                    : Colors.amber)
                                : Colors.grey,
                            label: Text(
                              driver.viewDuration != null
                                  ? (driver.isCompleteWatch!
                                      ? 'completed'
                                      : 'partially viewed')
                                  : 'Not View Yet',
                              style: TextStyle(fontSize: 14),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Quiz Status",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          driver.quizStatus != null
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Badge(
                                    backgroundColor:
                                        driver.quizStatus == "passed"
                                            ? Colors.green
                                            : driver.quizStatus == "failed"
                                                ? Colors.red
                                                : Colors.grey,
                                    label: Text(
                                      driver.quizStatus == "passed"
                                          ? "certified"
                                          : driver.quizStatus ?? "-",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                )
                              : Text('-'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Quiz Result",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                              "${driver?.quizResult != null ? "${driver.quizResult}%" : "-"}")
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
