import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:uscitylink/constant.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/model/training_model.dart';
import 'package:uscitylink/utils/device/device_utility.dart';
import 'package:uscitylink/views/widgets/document_download.dart';

class ResultView extends StatefulWidget {
  final String result;
  final Training training;
  const ResultView({super.key, required this.result, required this.training});

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  TrainingController _trainingController = Get.find<TrainingController>();
  static const colorizeColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];
  static const colorizeTextStyle = TextStyle(
    fontSize: 32.0,
  );
  @override
  Widget build(BuildContext context) {
    if (widget.result == "failed") {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            Positioned(
                left: 0, right: 0, child: Lottie.asset('assets/json/6.json')),
            Positioned(
              top: TDeviceUtils.getScreenHeight() * 0.40,
              left: 0,
              right: 0,
              child: AnimatedTextKit(
                animatedTexts: [
                  ColorizeAnimatedText(
                    textAlign: TextAlign.center,
                    'You are not qualified, try again!',
                    textStyle: colorizeTextStyle,
                    colors: colorizeColors,
                  ),
                ],
                isRepeatingAnimation: true,
                onTap: () {
                  print("Tap Event");
                },
              ),
            ),
            Positioned(
              top: TDeviceUtils.getScreenHeight() * 0.55,
              left: 0,
              right: 0,
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.back();
                      _trainingController.fetchTrainingVideos(page: 1);
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("Go Back"),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Lottie.asset('assets/json/1.json'),
          Lottie.asset('assets/json/2.json'),
          SizedBox(
              height: TDeviceUtils.getScreenHeight() * 0.9,
              child: Lottie.asset('assets/json/5.json')),
          Positioned(
            top: TDeviceUtils.getScreenHeight() * 0.45,
            left: TDeviceUtils.getScreenWidth(context) * 0.2,
            child: AnimatedTextKit(
              animatedTexts: [
                ColorizeAnimatedText(
                  'You are certified',
                  textStyle: colorizeTextStyle,
                  colors: colorizeColors,
                ),
              ],
              isRepeatingAnimation: true,
              onTap: () {
                print("Tap Event");
              },
            ),
          ),
          Positioned(
            top: TDeviceUtils.getScreenHeight() *
                0.55, // Keeps the vertical position
            left:
                0, // Ensures it is aligned to the left side (needed to center it horizontally)
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () {
                  Get.to(() => DocumentDownload(
                      file:
                          "${Constant.url}/driver/trainings/training-certificate/${widget.training.tainingId}?driverId=${widget.training.driverId}"));
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(6)),
                  child: Center(
                      child: Text(
                    "Download Certificate",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  )),
                ),
              ),
            ),
          ),
          Positioned(
            top: TDeviceUtils.getScreenHeight() *
                0.68, // Keeps the vertical position
            left:
                0, // Ensures it is aligned to the left side (needed to center it horizontally)
            right:
                0, // Ensures it is aligned to the right side (needed to center it horizontally)
            child: SizedBox(
              width: double.infinity, // Takes up full width
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.back();
                    _trainingController.fetchTrainingVideos(page: 1);
                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("Go Back Trainings"),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
