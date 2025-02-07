class TrainingModel {
  List<Training>? data;
  Pagination? pagination;

  TrainingModel({this.data, this.pagination});

  TrainingModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Training>[];
      json['data'].forEach((v) {
        data?.add(new Training.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data?.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination?.toJson();
    }
    return data;
  }
}

class Training {
  String? id;
  String? tainingId;
  String? driverId;
  String? viewDuration;
  bool? isCompleteWatch;
  String? createdAt;
  String? updatedAt;
  Trainings? trainings;
  String? quiz_status;

  Training(
      {this.id,
      this.tainingId,
      this.driverId,
      this.viewDuration,
      this.isCompleteWatch,
      this.createdAt,
      this.updatedAt,
      this.trainings,
      this.quiz_status});

  Training.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tainingId = json['tainingId'];
    driverId = json['driverId'];
    viewDuration = json['view_duration'];
    isCompleteWatch = json['isCompleteWatch'];
    quiz_status = json['quiz_status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    trainings = json['trainings'] != null
        ? new Trainings.fromJson(json['trainings'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tainingId'] = this.tainingId;
    data['driverId'] = this.driverId;
    data['view_duration'] = this.viewDuration;
    data['isCompleteWatch'] = this.isCompleteWatch;
    data['quiz_status'] = this.quiz_status;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.trainings != null) {
      data['trainings'] = this.trainings?.toJson();
    }
    return data;
  }
}

class Trainings {
  String? id;
  String? title;
  String? description;
  String? fileName;
  String? fileType;
  String? thumbnail;
  String? fileSize;
  String? mimeType;
  String? duration;
  String? key;
  String? createdAt;
  String? updatedAt;
  List<Questions>? questions;

  Trainings(
      {this.id,
      this.title,
      this.description,
      this.fileName,
      this.fileType,
      this.thumbnail,
      this.fileSize,
      this.mimeType,
      this.duration,
      this.key,
      this.createdAt,
      this.questions,
      this.updatedAt});

  Trainings.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    fileName = json['file_name'];
    fileType = json['file_type'];
    thumbnail = json['thumbnail'];
    fileSize = json['file_size'];
    mimeType = json['mime_type'];
    duration = json['duration'];
    key = json['key'];
    createdAt = json['createdAt'];

    updatedAt = json['updatedAt'];
    if (json['questions'] != null) {
      questions = <Questions>[];
      json['questions'].forEach((v) {
        questions?.add(new Questions.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['file_name'] = this.fileName;
    data['file_type'] = this.fileType;
    data['thumbnail'] = this.thumbnail;
    data['file_size'] = this.fileSize;
    data['mime_type'] = this.mimeType;
    data['duration'] = this.duration;
    data['key'] = this.key;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['questions'] = this.questions;
    return data;
  }
}

class Questions {
  String? id;
  String? tainingId;
  String? question;
  String? createdAt;
  String? updatedAt;
  List<Options>? options;

  Questions(
      {this.id,
      this.tainingId,
      this.question,
      this.createdAt,
      this.updatedAt,
      this.options});

  Questions.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tainingId = json['tainingId'];
    question = json['question'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    if (json['options'] != null) {
      options = <Options>[];
      json['options'].forEach((v) {
        options?.add(new Options.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tainingId'] = this.tainingId;
    data['question'] = this.question;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.options != null) {
      data['options'] = this.options?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Options {
  String? id;
  String? questionId;
  String? option;
  bool? isCorrect;
  String? createdAt;
  String? updatedAt;

  Options(
      {this.id,
      this.questionId,
      this.option,
      this.isCorrect,
      this.createdAt,
      this.updatedAt});

  Options.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    questionId = json['questionId'];
    option = json['option'];
    isCorrect = json['isCorrect'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['questionId'] = this.questionId;
    data['option'] = this.option;
    data['isCorrect'] = this.isCorrect;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}

class Pagination {
  int? currentPage;
  int? pageSize;
  int? total;
  int? totalPages;

  Pagination({this.currentPage, this.pageSize, this.total, this.totalPages});

  Pagination.fromJson(Map<String, dynamic> json) {
    currentPage = json['currentPage'];
    pageSize = json['pageSize'];
    total = json['total'];
    totalPages = json['totalPages'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['pageSize'] = this.pageSize;
    data['total'] = this.total;
    data['totalPages'] = this.totalPages;
    return data;
  }
}
