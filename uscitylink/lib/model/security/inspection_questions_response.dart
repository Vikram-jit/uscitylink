class InspectionQuestionsResponse {
  List<String> truckQuestions;
  List<String> trailerQuestions;

  InspectionQuestionsResponse({
    this.truckQuestions = const [],
    this.trailerQuestions = const [],
  });

  InspectionQuestionsResponse.fromJson(Map<String, dynamic> json)
      : truckQuestions = (json['truckQuestions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        trailerQuestions = (json['trailerQuestions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
}
