import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/model/training_model.dart';
import 'package:uscitylink/utils/constant/colors.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/driver/views/trainings/quiz_view.dart';
import 'package:video_player/video_player.dart';

class TrainingDetailView extends StatefulWidget {
  final String tiitle;
  final String id;
  final Trainings trainings;
  final Training training;
  const TrainingDetailView(
      {super.key,
      required this.tiitle,
      required this.id,
      required this.trainings,
      required this.training});

  @override
  State<TrainingDetailView> createState() => _TrainingDetailViewState();
}

class _TrainingDetailViewState extends State<TrainingDetailView> {
  late VideoPlayerController videoPlayerController;
  late Future<void> _initializeVideoPlayerFuture;
  late Duration _duration;
  late Duration _currentPosition;
  bool isComplete = false;
  bool _isInitialized = false;
  TrainingController _trainingController = Get.find<TrainingController>();
  @override
  void initState() {
    super.initState();
    if (widget.training.isCompleteWatch!) {
      setState(() {
        isComplete = true;
      });
    }
    videoPlayerController = new VideoPlayerController.networkUrl(
        Uri.parse('${Constant.aws}/${widget.trainings.key}'));

    _initializeVideoPlayerFuture = videoPlayerController.initialize().then((_) {
      setState(() {
        _isInitialized = true;
        _duration = videoPlayerController.value.duration;
        _currentPosition = videoPlayerController.value.position;
      });
    });
    videoPlayerController.addListener(() {
      setState(() {
        // Update the current position while the video plays
        if (_isInitialized) {
          if (widget.training.isCompleteWatch! == false &&
              videoPlayerController.value.isPlaying == false &&
              videoPlayerController.value.position.inSeconds > 1 &&
              (videoPlayerController.value.duration !=
                  videoPlayerController.value.position)) {
            _trainingController.updateDuration(widget.training.id!,
                videoPlayerController.value.position.toString(), false);
          }

          setState(() {
            // Update the current position while the video plays
            _currentPosition = videoPlayerController.value.position;
          });

          if (videoPlayerController.value.duration ==
                  videoPlayerController.value.position &&
              widget.training.isCompleteWatch! == false) {
            _trainingController.updateDuration(widget.training.id!,
                videoPlayerController.value.position.toString(), true);
            isComplete = true;
          }
        }
      });
    });
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
              backgroundColor: TColors.primary,
              title: Text(
                "${widget.tiitle}",
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
              height: TDeviceUtils.getScreenHeight() * 0.05,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      isComplete
                          ? TColors.primary
                          : TColors.primary
                              .withOpacity(0.7), // Dim the color when disabled
                    ),
                    shadowColor: MaterialStateProperty.all(
                        Colors.transparent), // Remove shadow when disabled
                  ),
                  onPressed: () {
                    Get.to(
                      () => QuizView(
                        trainingId: widget.training.tainingId!,
                        title: widget.training.trainings?.title ?? "",
                      ),
                    );
                  },
                  child: Text("Start Quiz"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
