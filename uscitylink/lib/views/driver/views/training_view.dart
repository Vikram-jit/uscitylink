import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/drawer/driver_custom_drawer.dart';
import 'package:uscitylink/views/driver/views/trainings/training_detail_view.dart';

class TrainingView extends StatefulWidget {
  TrainingView({super.key});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  TrainingController _trainingController = Get.find<TrainingController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _trainingController.fetchTrainingVideos(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    _trainingController.fetchTrainingVideos(page: 1);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: TColors.white,
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
              backgroundColor: TColors.primary,
              title: Text(
                "Training Section",
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
      body: Obx(
        () {
          if (_trainingController.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return RefreshIndicator(
            onRefresh: () => _trainingController.fetchTrainingVideos(page: 1),
            child: ListView.builder(
              controller: ScrollController()
                ..addListener(() {
                  // Don't load more if data is already loading
                  if (_trainingController.isLoading.value) return;

                  // Check if there are more pages and trigger data fetch if necessary
                  if (_trainingController.currentPage.value <
                      _trainingController.totalPages.value) {
                    if (_trainingController.trainings.isNotEmpty &&
                        _trainingController.trainings.last ==
                            _trainingController.trainings[
                                _trainingController.trainings.length - 1]) {
                      _trainingController.fetchTrainingVideos(
                          page: _trainingController.currentPage.value + 1);
                    }
                  }
                }),
              itemCount: _trainingController.trainings.length,
              itemBuilder: (context, index) {
                var training = _trainingController.trainings[index];

                return InkWell(
                  onTap: () {
                    Get.to(() => TrainingDetailView(
                          tiitle: training.trainings!.title!,
                          id: training.trainings!.id!,
                          trainings: training.trainings!,
                          training: training,
                        ));
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 5.0),
                    child: ListTile(
                      leading: training.trainings?.thumbnail != null
                          ? Image.network(
                              width: 70,
                              height: 70,
                              fit: BoxFit.contain,
                              "${Constant.aws}/${training.trainings?.thumbnail}")
                          : null,
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${training.trainings?.title}'),
                          if (training.quiz_status != null)
                            Chip(
                              backgroundColor: training.quiz_status == "passed"
                                  ? Colors.green
                                  : training.quiz_status == "failed"
                                      ? Colors.red
                                      : Colors.transparent,
                              label: Text(
                                "${training.quiz_status == "passed" ? "Certified"?.toUpperCase() : training.quiz_status?.toUpperCase()}",
                                style: TextStyle(
                                  color: training.quiz_status == "passed"
                                      ? Colors.white
                                      : training.quiz_status == "failed"
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            )
                        ],
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      trailing: Icon(Icons.arrow_right),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      drawer: DriverCustomDrawer(),
    );
  }
}
