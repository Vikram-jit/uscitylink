class InspectionQuestionAnswer {
  String question;
  String? status; // 'ok' | 'problem' | null (unanswered)

  InspectionQuestionAnswer({required this.question, this.status});

  InspectionQuestionAnswer.fromJson(Map<String, dynamic> json)
      : question = json['question'],
        status = json['status'];

  Map<String, dynamic> toJson() => {'question': question, 'status': status};
}
