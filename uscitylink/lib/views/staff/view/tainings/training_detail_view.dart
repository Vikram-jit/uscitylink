import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/model/training_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/driver/views/trainings/quiz_view.dart';
import 'package:uscitylink/views/staff/view/tainings/assgined_drivers_view.dart';
import 'package:video_player/video_player.dart';

class TrainingDetailView extends StatefulWidget {
  final Trainings trainings;
  const TrainingDetailView({
    super.key,
    required this.trainings,
  });

  @override
  State<TrainingDetailView> createState() => _TrainingDetailViewState();
}

class _TrainingDetailViewState extends State<TrainingDetailView> {
  late VideoPlayerController videoPlayerController;
  late Future<void> _initializeVideoPlayerFuture;

  bool _isInitialized = false;
  TrainingController _trainingController = Get.find<TrainingController>();
  @override
  void initState() {
    super.initState();

    videoPlayerController = new VideoPlayerController.networkUrl(
        Uri.parse('${Constant.aws}/${widget.trainings.key}'));

    _initializeVideoPlayerFuture =
        videoPlayerController.initialize().then((_) {});
  }

  @override
  void dispose() {
    videoPlayerController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        onPressed: () {
          Get.to(() => AssginedDriversView(
                trainingId: widget.trainings.id!,
              ));
        },
        label: Row(
          children: [
            Text("Assgined Drivers",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            SizedBox(
              width: 10,
            ),
            Icon(
              Icons.send,
              color: Colors.white,
              size: 24,
            )
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            AppBar(
              centerTitle: false,
              automaticallyImplyLeading: false,
              leading: InkWell(
                onTap: () {
                  _trainingController.fetchTrainingVideos(page: 1);
                  Get.back();
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
              backgroundColor: TColors.primaryStaff,
              title: Text(
                "${widget.trainings.title}",
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: TDeviceUtils.getScreenHeight() * 0.5,
              width: double.infinity,
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  return (snapshot.connectionState == ConnectionState.done)
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          child: Chewie(
                            controller: ChewieController(
                              videoPlayerController: videoPlayerController,
                              autoInitialize: true,
                              looping: false,
                              showOptions: true,
                              allowFullScreen: true,
                              errorBuilder: (context, errorMessage) {
                                return Center(
                                  child: Text(
                                    errorMessage,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 200,
                          child: Center(
                            child: (snapshot.connectionState !=
                                    ConnectionState.none)
                                ? CircularProgressIndicator()
                                : SizedBox(),
                          ),
                        );
                },
              ),
            ),
            SizedBox(
              height: TDeviceUtils.getScreenHeight() * 0.02,
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Description",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(
                    height: TDeviceUtils.getScreenHeight() * 0.01,
                  ),
                  Text(
                    "${widget.trainings.description}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(
                    height: TDeviceUtils.getScreenHeight() * 0.02,
                  ),
                  Container(
                    padding: EdgeInsets.zero,
                    width: double.infinity,
                    child: Card(
                      color: Colors.white,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Question List",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: TDeviceUtils.getScreenHeight() * 0.03,
                  ),
                  if (widget.trainings.questions == null) Text("No Questions"),
                  if (widget.trainings.questions != null)
                    ...widget.trainings.questions!.asMap().entries.map((entry) {
                      int index = entry.key; // index of the question
                      var question = entry.value; // the question itself
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Q${index + 1}). ${question?.question ?? 'No question available'}",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 10),
                          if (question.options != null &&
                              question.options != null)
                            ...question.options!.map((option) {
                              final optionId = option.id;
                              final optionText = option.option;

                              return CheckboxListTile(
                                activeColor: option.isCorrect ?? false
                                    ? Colors.green
                                    : Colors.white,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                    "${optionText} " ?? 'No option available'),
                                value: option.isCorrect ?? false,
                                onChanged: (bool? value) {},
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            }).toList()
                          else
                            Text("No options available",
                                style: TextStyle(color: Colors.grey)),
                          Divider(),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      );
                    }).toList(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
