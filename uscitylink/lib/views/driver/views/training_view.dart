import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/dashboard_controller.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/trainings/training_detail_view.dart';

class TrainingView extends StatefulWidget {
  TrainingView({super.key});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  TrainingController _trainingController = Get.find<TrainingController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DashboardController _dashboardController = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _trainingController.fetchTrainingVideos(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Colors.white),
            onPressed: () {
              _dashboardController.getDashboard();
              Get.back();
            },
          ),
          backgroundColor: TColors.navyHeader,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Training',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
        body: Obx(() {
          if (_trainingController.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: TColors.navyHeader));
          }
          if (_trainingController.trainings.isEmpty) {
            return RefreshIndicator(
              color: TColors.navyHeader,
              onRefresh: () =>
                  _trainingController.fetchTrainingVideos(page: 1),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined,
                              size: 44, color: Colors.grey.shade300),
                          const SizedBox(height: 14),
                          Text(
                            'No training videos yet',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: TColors.navyHeader,
            onRefresh: () => _trainingController.fetchTrainingVideos(page: 1),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              controller: ScrollController()
                ..addListener(() {
                  if (_trainingController.isLoading.value) return;
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
                final training = _trainingController.trainings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TrainingCard(
                    thumbnail: training.trainings?.thumbnail,
                    title: training.trainings?.title ?? 'Untitled',
                    quizStatus: training.quiz_status,
                    onTap: () {
                      Get.to(() => TrainingDetailView(
                            tiitle: training.trainings!.title!,
                            id: training.trainings!.id!,
                            trainings: training.trainings!,
                            training: training,
                          ));
                    },
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final String? thumbnail;
  final String title;
  final String? quizStatus;
  final VoidCallback onTap;

  const _TrainingCard({
    required this.thumbnail,
    required this.title,
    required this.quizStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? chipColor;
    String? chipText;
    if (quizStatus == 'passed') {
      chipColor = const Color(0xFF16A34A);
      chipText = 'CERTIFIED';
    } else if (quizStatus == 'failed') {
      chipColor = const Color(0xFFEF4444);
      chipText = 'FAILED';
    } else if (quizStatus != null) {
      chipColor = Colors.grey.shade400;
      chipText = quizStatus!.toUpperCase();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumbnail != null
                  ? Image.network(
                      "${Constant.aws}/$thumbnail",
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: const Color(0xFF9333EA).withOpacity(0.08),
                      child: const Icon(Icons.play_circle_fill_rounded,
                          color: Color(0xFF9333EA), size: 28),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  if (chipText != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: chipColor!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        chipText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: chipColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
