import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/utils/constant/Colors.dart';
import 'package:uscitylink/views/staff/view/tainings/training_detail_view.dart';

class StaffTrainingsView extends StatefulWidget {
  const StaffTrainingsView({super.key});

  @override
  State<StaffTrainingsView> createState() => _StaffTrainingsViewState();
}

class _StaffTrainingsViewState extends State<StaffTrainingsView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TrainingController _trainingController = Get.put(TrainingController());
  DashboardController _dashboardController = Get.find<DashboardController>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _trainingController.fetchStaffTrainingVideos(page: 1);
  }

  @override
  Widget build(BuildContext context) {
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
                  _dashboardController.getStaffDashboard();
                  Navigator.pop(context); // Navigate back
                },
              ),
              backgroundColor: TColors.primaryStaff,
              title: Text(
                "Tarinings Video",
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
                        // controller: _templateController.searchController,
                        // onChanged: _templateController.onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search training by title...",
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
      body: Obx(
        () {
          if (_trainingController.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                _trainingController.fetchStaffTrainingVideos(page: 1),
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
                      _trainingController.fetchStaffTrainingVideos(
                          page: _trainingController.currentPage.value + 1);
                    }
                  }
                }),
              itemCount: _trainingController.staff_trainings.length,
              itemBuilder: (context, index) {
                var training = _trainingController.staff_trainings[index];

                return InkWell(
                  onTap: () {
                    Get.to(() => TrainingDetailView(
                          trainings: training,
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
                      leading: Image.network(
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                          "${Constant.aws}/${training?.thumbnail}"),
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${training?.title}'),
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
    );
  }
}
