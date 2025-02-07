import 'package:uscitylink/model/staff/channel_chat_user_model.dart';

class AssginedDriverModel {
  AssginDriver? data;
  Pagination? pagination;

  AssginedDriverModel({this.data, this.pagination});

  AssginedDriverModel.fromJson(Map<String, dynamic> json) {
    data =
        json['data'] != null ? new AssginDriver.fromJson(json['data']) : null;
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination?.toJson();
    }
    return data;
  }
}

class AssginDriver {
  Training? training;
  List<Drivers>? drivers;

  AssginDriver({this.training, this.drivers});

  AssginDriver.fromJson(Map<String, dynamic> json) {
    training = json['training'] != null
        ? new Training.fromJson(json['training'])
        : null;
    if (json['drivers'] != null) {
      drivers = <Drivers>[];
      json['drivers'].forEach((v) {
        drivers?.add(new Drivers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.training != null) {
      data['training'] = this.training?.toJson();
    }
    if (this.drivers != null) {
      data['drivers'] = this.drivers?.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Training {
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

  Training(
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
      this.updatedAt});

  Training.fromJson(Map<String, dynamic> json) {
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
    return data;
  }
}

class Drivers {
  String? id;
  String? tainingId;
  String? driverId;
  String? viewDuration;
  String? quizStatus;
  String? quizResult;
  bool? isCompleteWatch;
  String? createdAt;
  String? updatedAt;
  UserProfile? userProfiles;

  Drivers(
      {this.id,
      this.tainingId,
      this.driverId,
      this.viewDuration,
      this.quizStatus,
      this.quizResult,
      this.isCompleteWatch,
      this.createdAt,
      this.updatedAt,
      this.userProfiles});

  Drivers.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tainingId = json['tainingId'];
    driverId = json['driverId'];
    viewDuration = json['view_duration'];
    quizStatus = json['quiz_status'];
    quizResult = json['quiz_result'];
    isCompleteWatch = json['isCompleteWatch'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    userProfiles = json['user_profiles'] != null
        ? new UserProfile.fromJson(json['user_profiles'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tainingId'] = this.tainingId;
    data['driverId'] = this.driverId;
    data['view_duration'] = this.viewDuration;
    data['quiz_status'] = this.quizStatus;
    data['quiz_result'] = this.quizResult;
    data['isCompleteWatch'] = this.isCompleteWatch;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    if (this.userProfiles != null) {
      data['user_profiles'] = this.userProfiles?.toJson();
    }
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
