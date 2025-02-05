import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uscitylink/controller/training_controller.dart';
import 'package:uscitylink/utils/constant/colors.dart';

class QuizView extends StatefulWidget {
  final String trainingId;
  final String title;
  const QuizView({super.key, required this.trainingId, required this.title});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  TrainingController _trainingController = Get.find<TrainingController>();

  // Selected answers map
  Map<String, Set<String>> selectedAnswers = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _trainingController.fetchQuestion(id: widget.trainingId);
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
                  Get.back();
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
              backgroundColor: TColors.primary,
              title: Text(
                "${widget.title}",
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(
          () {
            if (_trainingController.loadQuiz.value) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            return Column(
              children: [
                Expanded(
                    child: ListView.builder(
                  itemCount:
                      _trainingController.questions.value.questions?.length ??
                          0, // Safely handle null item count
                  itemBuilder: (context, index) {
                    // Safely get question and options
                    final question =
                        _trainingController.questions.value.questions?[index];
                    final options = question?.options;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Safely handle null for question text
                        Text(
                          "Q${index + 1}). ${question?.question ?? 'No question available'}",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(
                            height:
                                10), // Adjust the space between the question and options

                        // Safely handle null for options
                        if (options != null && options.isNotEmpty)
                          ...options.map((option) {
                            final optionId = option.id;
                            final optionText = option.option;

                            // Ensure optionText is not null
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(optionText ??
                                  'No option available'), // Fallback if optionText is null
                              value: selectedAnswers[question?.id]
                                      ?.contains(optionId) ??
                                  false, // Handle if question or optionId is null
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    if (selectedAnswers[question?.id] == null) {
                                      selectedAnswers[question!.id!] =
                                          Set<String>();
                                    }
                                    selectedAnswers[question?.id]?.add(
                                        optionId!); // Ensure optionId is not null
                                  } else {
                                    selectedAnswers[question?.id]
                                        ?.remove(optionId);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity
                                  .leading, // Checkbox on left
                            );
                          }).toList()
                        else
                          Text("No options available",
                              style: TextStyle(color: Colors.grey)),
                        Divider(),
                        SizedBox(
                          height: 10,
                        ),
                        // Handle the case when options is null or empty
                      ],
                    );
                  },
                )),
                SizedBox(
                  height: 20,
                ),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(TColors.primary),
                      shadowColor: MaterialStateProperty.all(
                          Colors.transparent), // Remove shadow when disabled
                    ),
                    onPressed: () {
                      _trainingController.submitQuiz(
                          widget.trainingId, selectedAnswers);
                    },
                    child: Text("Submit"),
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
