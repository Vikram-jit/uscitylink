import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/views/driver/views/trainings/training_detail_view.dart';

class TrainingView extends StatelessWidget {
  TrainingView({super.key});
  TrainingController _trainingController = Get.put(TrainingController());
  @override
  Widget build(BuildContext context) {
    _trainingController.fetchTrainingVideos(page: 1);
    return Scaffold(
      backgroundColor: TColors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
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
          return ListView.builder(
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
                    leading: Image.network(
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                        "${Constant.aws}/${training.trainings?.thumbnail}"),
                    title: Text('${training.trainings?.title}'),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    trailing: Icon(Icons.arrow_right),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
